/* *************************************************************************************************
 QuotedStringTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class QuotedStringTests {
  func test_quote() {
    #expect("ABC\\DEF"._quotedString == "\"ABC\\\\DEF\"")
    #expect("あ"._quotedString == nil)
  }

  @Test func test_unquote() {
    #expect("\"ABC\\\\DEF\""._unquotedString == "ABC\\DEF")
    #expect("\"NOTCLOSED"._unquotedString == nil)
  }
}
#else
import XCTest

final class QuotedStringTests: XCTestCase {
  func test_quote() {
    XCTAssertEqual("ABC\\DEF"._quotedString, "\"ABC\\\\DEF\"")
    XCTAssertEqual("あ"._quotedString, nil)
  }
  
  func test_unquote() {
    XCTAssertEqual("\"ABC\\\\DEF\""._unquotedString, "ABC\\DEF")
    XCTAssertEqual("\"NOTCLOSED"._unquotedString, nil)
  }
}
#endif
