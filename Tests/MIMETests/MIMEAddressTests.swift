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
    #expect(literal.leadingCFWS == [MIMEComment([.text("foo")])])
    #expect(literal.text == "[bar]")
    #expect(literal.trailingCFWS == [MIMEComment([.text("baz")])])
  }

  @Test func addrSpecParser() throws {
    do {
      let addrSpec = try #require(MIMEAddressSpecification(parsing: "addr@spec.parser"))

      let localPart = addrSpec.localPart
      #expect(localPart.isDotAtom)
      #expect(localPart.leadingCFWS.isNil)
      #expect(localPart.trailingCFWS.isNil)
      #expect(localPart.dotAtom?.text == "addr")

      let domainPortion = addrSpec.domainPortion
      #expect(domainPortion.isDotAtom)
      #expect(domainPortion.leadingCFWS.isNil)
      #expect(domainPortion.trailingCFWS.isNil)
      #expect(domainPortion.dotAtom?.text == "spec.parser")
    }

    do {
      let addrSpec = try #require(
        MIMEAddressSpecification(parsing: #"(My name is)"YOCKOW"(.)@(Domain literal can contain)[any characters you want](excluding some characters.)"#)
      )

      let localPart = addrSpec.localPart
      #expect(localPart.isQuotedString)
      #expect(localPart.quotedString?.leadingCFWS == [MIMEComment([.text("My name is")])])
      #expect(localPart.quotedString?.content == "YOCKOW")
      #expect(localPart.quotedString?.trailingCFWS == [MIMEComment([.text(".")])])

      let domainPortion = addrSpec.domainPortion
      #expect(domainPortion.isDomainLiteral)
      #expect(domainPortion.domainLiteral?.leadingCFWS == [MIMEComment([.text("Domain literal can contain")])])
      #expect(domainPortion.domainLiteral?.text == "[any characters you want]")
      #expect(domainPortion.domainLiteral?.trailingCFWS == [MIMEComment([.text("excluding some characters.")])])
    }
  }

  @Test func angleAddr() throws {
    do {
      let angleAddr = try #require(MIMEAngleBracketEnclosedAddress(parsing: "<angle@bracket.com>"))
      #expect(angleAddr.leadingCFWS.isNil)
      #expect(angleAddr.trailingCFWS.isNil)
      #expect(angleAddr.addressSpecification.localPart.dotAtom?.text == "angle")
      #expect(angleAddr.addressSpecification.domainPortion.dotAtom?.text == "bracket.com")
    }

    do {
      let angleAddr = try #require(MIMEAngleBracketEnclosedAddress(parsing: "(foo)<bar@baz>(qux)"))
      #expect(angleAddr.leadingCFWS == [MIMEComment([.text("foo")])])
      #expect(angleAddr.addressSpecification.localPart.dotAtom?.text == "bar")
      #expect(angleAddr.addressSpecification.domainPortion.dotAtom?.text == "baz")
      #expect(angleAddr.trailingCFWS == [MIMEComment([.text("qux")])])
    }
  }

  @Test func nameAddress() throws {
    do {
      let onlyAngleAddr = try #require(MIMENameAddress(parsing: "<angle@bracket.com>"))
      #expect(onlyAngleAddr.displayName.isNil)
      #expect(onlyAngleAddr.address.addressSpecification.localPart.dotAtom?.text == "angle")
      #expect(onlyAngleAddr.address.addressSpecification.domainPortion.dotAtom?.text == "bracket.com")
    }

    do {
      let fullNameAddr = try #require(MIMENameAddress(parsing: #"(1)atom(2)"quoted-string"(3)<local.part@domain.portion>(4)"#))

      let displayName = try #require(fullNameAddr.displayName)
      guard displayName._entity.wordCount == 2 else {
        Issue.record("Unexpected count.")
        return
      }
      #expect(displayName._entity.leadingCFWS == [MIMEComment([.text("1")])])
      #expect(displayName._entity.word(at: 0).isAtom)
      #expect(displayName._entity.word(at: 0).trailingCFWS == [MIMEComment([.text("2")])])
      #expect(displayName._entity.word(at: 1).isQuotedString)
      #expect(displayName._entity.word(at: 1).trailingCFWS == [MIMEComment([.text("3")])])

      #expect(fullNameAddr.address.addressSpecification.localPart.dotAtom?.text == "local.part")
      #expect(fullNameAddr.address.addressSpecification.domainPortion.dotAtom?.text == "domain.portion")
      #expect(fullNameAddr.address.trailingCFWS == [MIMEComment([.text("4")])])
    }
  }

  @Test func mailBox() throws {
    func __parse(_ string: String) -> MIMEMailBox? {
      return MIMEMailBoxParser<String>.parse(string)?.output
    }

    #expect(__parse("foo-bar").isNil)
    #expect(__parse("name <loca.part@domain.portion>")?.isNameAddress == true)
    #expect(__parse("<loca.part@domain.portion>")?.isNameAddress == true)
    #expect(__parse("loca.part@domain.portion")?.isAddressSpecification == true)
  }

  @Test func mailBoxList() throws {
    let string: String = [
      "(comment)",
      "person1 <person.1@domain.portion>,",
      "person2 <person.2@domain.portion>,",
      "<person.3@domain.portion>,",
      "person.4@domain.portion"
    ].joined(separator: FWS)

    let list = try #require(MIMEMailBoxListParser.parse(string)?.output)
    guard list.count == 4 else {
      Issue.record("Unexpected count?! (Actual count: \(list.count))")
      return
    }

    #expect(!list.first.leadingCFWS.isNil)
    #expect(list.first.displayName?.phrase.words.first.atom?.text == "person1")
    #expect(list.first.addressSpecification.localPart.dotAtom?.text == "person.1")
    #expect(list.first.addressSpecification.domainPortion.dotAtom?.text == "domain.portion")

    #expect(list[1].displayName?.phrase.words.first.atom?.text == "person2")
    #expect(list[1].addressSpecification.localPart.dotAtom?.text == "person.2")
    #expect(list[1].addressSpecification.domainPortion.dotAtom?.text == "domain.portion")

    #expect(list[2].displayName.isNil)
    #expect(list[2].addressSpecification.localPart.dotAtom?.text == "person.3")
    #expect(list[2].addressSpecification.domainPortion.dotAtom?.text == "domain.portion")

    #expect(list.last.displayName.isNil)
    #expect(list.last.addressSpecification.localPart.dotAtom?.text == "person.4")
    #expect(list.last.addressSpecification.domainPortion.dotAtom?.text == "domain.portion")
  }

  @Test(arguments: [
    "name:;",
    "name:(no list here);(comment)",
    "name:local@domain;",
  ]) func group(argument: String) throws {
    #expect(!MIMEAddressGroupParser<String>.parse(argument).isNil)
  }
}
