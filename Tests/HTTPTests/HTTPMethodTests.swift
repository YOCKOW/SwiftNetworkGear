/* *************************************************************************************************
 HTTPMethodTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct HTTPMethodTests {
  @Test func test_Hashable() throws {
    #expect(try HTTPMethod.get == #require(HTTPMethod(rawValue: "gEt")))
    #expect(try HTTPMethod.get.hashValue == #require(HTTPMethod(rawValue: "gEt")).hashValue)

    let upperMethodString = try #require(HTTPMethodString("FOO-BAR"))
    let lowerMethodString = try #require(HTTPMethodString("foo-bar"))
    #expect(upperMethodString == lowerMethodString)
    #expect(upperMethodString.hashValue == lowerMethodString.hashValue)

    let upperMethod = HTTPMethod.otherMethod(upperMethodString)
    let lowerMethod = HTTPMethod.otherMethod(lowerMethodString)
    #expect(upperMethod == lowerMethod)
    #expect(upperMethod.hashValue == lowerMethod.hashValue)
  }
}
