/* *************************************************************************************************
 MIMECommentTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing
import yExtensions

@Suite struct MIMECommentTests {
  @Test func test_parser() {
    #expect(MIMEComment(parsing: "foo").isNil)
    #expect(MIMEComment(parsing: "(open").isNil)
    #expect(MIMEComment(parsing: "((double)").isNil)

    #expect(MIMEComment(parsing: "(comment)") == MIMEComment([.text("comment")]))
    #expect(MIMEComment(parsing: #"(comment\ escaped)"#) == MIMEComment([.text("comment escaped")]))

    let FWS = "\u{0D}\u{0A} "
    let complexComment = [
      "(",
      "foo",
      "(bar",
      "(baz))",
      "hoge",
      #"\(not\ comment\)"#,
      ")",
    ].joined(separator: FWS)
    #expect(
      MIMEComment(parsing: complexComment) ==
      MIMEComment([
        .text("foo"),
        .comment([
          .text("bar"),
          .comment([
            .text("baz")
          ]),
        ]),
        .text("hoge(not comment)"),
      ])
    )
  }
}
