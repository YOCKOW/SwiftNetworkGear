/* *************************************************************************************************
 MIMECommentTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing
import yExtensions

let FWS = "\u{0D}\u{0A} "

@Suite struct MIMECommentTests {
  @Test func test_parser() {
    #expect(MIMEComment(parsing: "foo").isNil)
    #expect(MIMEComment(parsing: "(open").isNil)
    #expect(MIMEComment(parsing: "((double)").isNil)

    #expect(MIMEComment(parsing: "(comment)") == MIMEComment([.text("comment")]))
    #expect(MIMEComment(parsing: #"(comment\ escaped)"#) == MIMEComment([.text("comment escaped")]))

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

  @Test func test_CFWSParser() {
    typealias __Parser = MIMECommentCoexistableFoldingWhitespaceParser<String>
    #expect(__Parser.parse("foo").isNil)
    #expect(!__Parser.parse(FWS).isNil)

    let cfwsString = [
      "",
      "(comment1)",
      "(comment2)(comment3)",
      "(",
      "comment4-1(comment5)comment4-2",
      ")",
      "",
    ].joined(separator: FWS)
    #expect(__Parser.parse(cfwsString)?.output == [
      MIMEComment([.text("comment1")]),
      MIMEComment([.text("comment2")]),
      MIMEComment([.text("comment3")]),
      MIMEComment([
        .text("comment4-1"),
        .comment([.text("comment5")]),
        .text("comment4-2"),
      ])
    ])
  }
}
