/* *************************************************************************************************
 MIMEAtomTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing
import yExtensions

private typealias _TestArgument = (
  string: String,
  expected: ([MIMEComment]?, String, [MIMEComment]?)?
)

@Suite struct `MIME[Dot]AtomTests` {
  @Test(
    arguments: [
      ("...", nil),
      ("atom", (nil, "atom", nil)),
      (
        "(leading\\ comment)atom",
        (
          [MIMEComment([.text("leading comment")])],
          "atom",
          nil,
        )
      ),
      (
        "atom(trailing\\ comment)",
        (
          nil,
          "atom",
          [MIMEComment([.text("trailing comment")])],
        ),
      ),
      (
        "\(FWS)(leading\\ comment)\(FWS)atom\(FWS)(trailing\\ comment)",
        (
          [MIMEComment([.text("leading comment")])],
          "atom",
          [MIMEComment([.text("trailing comment")])],
        )
      ),
    ] as Array<_TestArgument>
  ) func test_atomParser(argument: (string: String, expected: ([MIMEComment]?, String, [MIMEComment]?)?)) throws {
    let createdAtom = MIMEAtom(parsing: argument.string)

    guard let expected = argument.expected else {
      #expect(createdAtom.isNil)
      return
    }
    let atom = try #require(createdAtom)
    #expect(atom.leadingComments == expected.0)
    #expect(atom.text == expected.1)
    #expect(atom.trailingComments == expected.2)
  }

  @Test(
    arguments: [
      ("...", nil),
      ("YOCKOW.jp", (nil, "YOCKOW.jp", nil)),
      (
        "(leading\\ comment)YOCKOW.jp",
        (
          [MIMEComment([.text("leading comment")])],
          "YOCKOW.jp",
          nil,
        )
      ),
      (
        "YOCKOW.jp(trailing\\ comment)",
        (
          nil,
          "YOCKOW.jp",
          [MIMEComment([.text("trailing comment")])],
        ),
      ),
      (
        "\(FWS)(leading\\ comment)\(FWS)YOCKOW.jp\(FWS)(trailing\\ comment)",
        (
          [MIMEComment([.text("leading comment")])],
          "YOCKOW.jp",
          [MIMEComment([.text("trailing comment")])],
        )
      ),
    ] as Array<_TestArgument>
  ) func test_dotAtomParser(argument: (string: String, expected: ([MIMEComment]?, String, [MIMEComment]?)?)) throws {
    let createdDotAtom = MIMEDotAtom(parsing: argument.string)

    guard let expected = argument.expected else {
      #expect(createdDotAtom.isNil)
      return
    }
    let dotAtom = try #require(createdDotAtom)
    #expect(dotAtom.leadingComments == expected.0)
    #expect(dotAtom.text == expected.1)
    #expect(dotAtom.trailingComments == expected.2)
  }

  @Test func mutualInitializers() throws {
    let atom = try #require(MIMEAtom(parsing: "(a)b(c)"))
    let dotAtom = MIMEDotAtom(atom)

    #expect(dotAtom.leadingComments == atom.leadingComments)
    #expect(dotAtom.text == atom.text)
    #expect(dotAtom.trailingComments == atom.trailingComments)

    let reAtom = try #require(MIMEAtom(dotAtom))
    #expect(reAtom == atom)
  }
}
