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

  @Test func test_appending() throws {
    let q1 = try #require(QuotedString(quoting: ##"A"B"C"##))
    let q2 = try #require(QuotedString(quoting: ##""D"E"F"##))
    let appended = q1.appending(q2)
    #expect(appended.quotedString == ##""A\"B\"C\"D\"E\"F""##)
    #expect(appended.content == ##"A"B"C"D"E"F"##)
  }
}
