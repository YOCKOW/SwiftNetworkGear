/* *************************************************************************************************
 MIMEAddressTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct MIMEAddressTests {
  @Test func domainLiteralParser() throws {
    let literal = try #require(MIMEDomainLiteral(parsing: "(foo)[bar](baz)"))
    #expect(literal.leadingComments == [MIMEComment([.text("foo")])])
    #expect(literal.text == "[bar]")
    #expect(literal.trailingComments == [MIMEComment([.text("baz")])])
  }

  @Test func addrSpecParser() throws {
    do {
      let addrSpec = try #require(MIMEAddressSpecification(parsing: "YOCKOW@YOCKOW.jp"))

      let localPart = addrSpec.localPart
      #expect(localPart.isDotAtom)
      #expect(localPart.leadingComments.isNil)
      #expect(localPart.trailingComments.isNil)
      #expect(localPart.dotAtom?.text == "YOCKOW")

      let domainPortion = addrSpec.domainPortion
      #expect(domainPortion.isDotAtom)
      #expect(domainPortion.leadingComments.isNil)
      #expect(domainPortion.trailingComments.isNil)
      #expect(domainPortion.dotAtom?.text == "YOCKOW.jp")
    }

    do {
      let addrSpec = try #require(
        MIMEAddressSpecification(parsing: #"(My name is)"YOCKOW"(.)@(Domain literal can contain)[any characters you want](excluding some characters.)"#)
      )

      let localPart = addrSpec.localPart
      #expect(localPart.isQuotedString)
      #expect(localPart.quotedString?.leadingComments == [MIMEComment([.text("My name is")])])
      #expect(localPart.quotedString?.content == "YOCKOW")
      #expect(localPart.quotedString?.trailingComments == [MIMEComment([.text(".")])])

      let domainPortion = addrSpec.domainPortion
      #expect(domainPortion.isDomainLiteral)
      #expect(domainPortion.domainLiteral?.leadingComments == [MIMEComment([.text("Domain literal can contain")])])
      #expect(domainPortion.domainLiteral?.text == "[any characters you want]")
      #expect(domainPortion.domainLiteral?.trailingComments == [MIMEComment([.text("excluding some characters.")])])
    }
  }

}
