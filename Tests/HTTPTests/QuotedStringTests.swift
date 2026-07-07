/* *************************************************************************************************
 QuotedStringTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite final class QuotedStringTests {
  @Test func test_quote() {
    #expect("ABC\\DEF"._quotedString == "\"ABC\\\\DEF\"")
    #expect("あ"._quotedString == nil)
  }

  @Test func test_unquote() {
    #expect("\"ABC\\\\DEF\""._unquotedString == "ABC\\DEF")
    #expect("\"NOTCLOSED"._unquotedString == nil)
  }
}
