/* *************************************************************************************************
 MIME+TokenTypesTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct MIMEWordTests {
  @Test func test_parser() throws {
    #expect(MIMEWord(parsing: "A B").isNil)

    let atomWord = try #require(MIMEWord(parsing: "(leading comment)atom(trailing comment)"))
    #expect(atomWord.isAtom)
    #expect(atomWord.atom?.leadingComments == [MIMEComment([.text("leading comment")])])
    #expect(atomWord.atom?.text == "atom")
    #expect(atomWord.atom?.trailingComments == [MIMEComment([.text("trailing comment")])])

    let qsWord = try #require(MIMEWord(parsing: #"(leading comment)"quoted-string"(trailing comment)"#))
    #expect(qsWord.isQuotedString)
    #expect(qsWord.quotedString?.leadingComments == [MIMEComment([.text("leading comment")])])
    #expect(qsWord.quotedString?.content == "quoted-string")
    #expect(qsWord.quotedString?.trailingComments == [MIMEComment([.text("trailing comment")])])
  }
}

@Suite struct MIMEPhraseTests {
  @Test func test_parser() throws {
    let phrase = try #require(MIMEPhraseParser<String>.parse(
      #"(leading comment)atom(interjected comment)"quoted-string"(trailing comment)"#
    )?.output)
    guard phrase._words.count == 2 else {
      Issue.record("Unexpected word count?! (\(phrase._words.count))")
      return
    }
    #expect(phrase.word(at: 0).isAtom)
    #expect(phrase.word(at: 0).atom?.leadingComments == [MIMEComment([.text("leading comment")])])
    #expect(phrase.word(at: 0).atom?.text == "atom")
    #expect(phrase.word(at: 0).atom?.trailingComments == [MIMEComment([.text("interjected comment")])])

    #expect(phrase.word(at: 1).isQuotedString)
    #expect(phrase.word(at: 1).quotedString?.leadingComments == nil)
    #expect(phrase.word(at: 1).quotedString?.content == "quoted-string")
    #expect(phrase.word(at: 1).quotedString?.trailingComments == [MIMEComment([.text("trailing comment")])])
  }
}

@Suite struct MIMEUnstructuredHeaderFieldValueTests {
  @Test func test_parser() throws {
    let value = try #require(
      MIMEUnstructuredHeaderFieldValueParser<String>.parse("     foo bar baz     ")?.output
    )
    #expect(value.rawValue == " foo bar baz ")
  }
}
