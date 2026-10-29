/* *************************************************************************************************
 MIMEQuotedStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import NetworkGear
import Testing

@Test func test_MIMEQuotedStringParser() throws {
  #expect(MIMEQuotedString(parsing: #""""#)?.content.isEmpty == true)
  #expect(MIMEQuotedString(parsing: #""A\ B""#)?.content == "A B")

  let complexString = """
  (
    leading\\ comment
  )
  "quoted
  content"
  (
    trailing comment
  )
  """.split(whereSeparator: { $0.isNewline }).joined(separator: "\u{0D}\u{0A}  ")
  let complex = try #require(MIMEQuotedString(parsing: complexString))
  #expect(try complex.leadingComments == [MIMEComment([.text("leading comment")])])
  #expect(complex.content == "quoted content")
  #expect(try complex.trailingComments == [MIMEComment([.text("trailing comment")])])
}
