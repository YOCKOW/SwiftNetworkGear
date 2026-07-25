/* *************************************************************************************************
 PercentEncodedStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing
import yExtensions

@Suite final class PercentEncodedStringTests {
  @Test func test_decoding() {
    #expect(PercentEncodedString(encodedString: "A").decodedString == "A")
    #expect(PercentEncodedString(validating: "%Q").isNil)
    #expect(PercentEncodedString(encodedString: "A%42C").decodedString == "ABC")
    #expect(
      PercentEncodedString(
        encodedString: "%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A"
      ).decodedString == "あいうえお"
    )
    #expect(
      PercentEncodedString(
        encodedString: "%82%a0%82%A2%82%a4%82%A6%82%a8"
      ).decodedString(
        usingStringEncoding: .shiftJIS
      ) == "あいうえお"
    )
  }

  @Test func test_parser() throws {
    var parser = PercentEncodedStringParser(
      input: "%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A;",
      allowedNonEncodedUTF8CodeUnits: \._isAvailableInExtendedValueWithoutPercentEncoding
    )
    let result = try #require(parser.parse() ?? nil)
    #expect(result.output.decodedString == "あいうえお")
    #expect(result.endIndex < parser.input.endIndex && parser.input[result.endIndex] == ";")
  }

  @Test func test_asBidirectionalCollection() {
    let percentEncodedString = PercentEncodedString(encodedString: "A%42C")
    let percentEncodedStringAsArray = Array<PercentEncodedString.Element>(percentEncodedString)
    #expect(percentEncodedString.count == 3)
    #expect(percentEncodedString.count == percentEncodedStringAsArray.count)
    #expect(percentEncodedString.first == .rawCodeUnit(0x41))
    #expect(percentEncodedString.first == percentEncodedStringAsArray.first)
    #expect(percentEncodedString.dropFirst().first == .percentEncoded(upperHex: 0x34, lowerHex: 0x32))
    #expect(percentEncodedString.dropFirst().first == percentEncodedStringAsArray.dropFirst().first)
    #expect(percentEncodedString.last == .rawCodeUnit(0x43))
    #expect(percentEncodedString.last == percentEncodedStringAsArray.last)

    let cIndex = percentEncodedString.index(before: percentEncodedString.endIndex)
    #expect(percentEncodedString[cIndex] == .rawCodeUnit(0x43))
    let bIndex = percentEncodedString.index(before: cIndex)
    #expect(percentEncodedString[bIndex] == .percentEncoded(upperHex: 0x34, lowerHex: 0x32))
    let aIndex = percentEncodedString.index(before: bIndex)
    #expect(percentEncodedString[aIndex] == .rawCodeUnit(0x41))
  }
}
