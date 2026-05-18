/* *************************************************************************************************
 StringParserTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

struct DigitParser<Input: StringProtocol>: StringParser, _UTF8Parser {
  typealias Output = Int
  let string: Input
  let utf8: Input.UTF8View
  init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }
  mutating func parse() -> (output: Int, endIndex: Input.Index)? {
    var index = self.utf8.startIndex
    guard let parsedResult = self.parseString(from: &index, while: \._isDigit) else {
      return nil
    }
    return (Int(String(string[..<parsedResult.endIndex]))!, parsedResult.endIndex)
  }
}

struct HiraganaParser<Input: StringProtocol>: StringParser {
  typealias Output = Input.SubSequence
  let string: Input
  init(input: Input) {
    self.string = input
  }
  mutating func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
    let scalars = string.unicodeScalars
    var index = scalars.startIndex
    while index < scalars.endIndex {
      let scalar = scalars[index]
      guard (0x3040...0x309F as ClosedRange<UInt32>).contains(scalar.value) else {
        break
      }
      scalars.formIndex(after: &index)
    }
    guard index > scalars.startIndex else {
      return nil
    }
    return (output: string[..<index], endIndex: index)
  }
}

@Suite struct StringParserTests {
  @Test func test_CombinedParser() {
    typealias _DigitHiraganaParser = CombinedParser<String, DigitParser<String>, HiraganaParser<Substring>>
    #expect(_DigitHiraganaParser.parse("0123").isNil)
    #expect(_DigitHiraganaParser.parse("0123ABC").isNil)
    #expect(_DigitHiraganaParser.parse("ABC").isNil)
    #expect(_DigitHiraganaParser.parse("あいうえお").isNil)
    #expect(!_DigitHiraganaParser.parse("0123あいうえお").isNil)
    #expect(!_DigitHiraganaParser.parse("0123あいうえおABC").isNil)
  }
}
