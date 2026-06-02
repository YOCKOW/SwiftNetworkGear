/* *************************************************************************************************
 HTTPHeaderFieldParameterTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
@testable import NetworkGear
import Testing

@Suite struct HTTPHeaderFieldParameterTests {
  typealias NameParserTestPair = (string: String, expect: @Sendable (_ParameterName) throws -> Void)

  static let nameParserTestPairs: Array<NameParserTestPair> = [
    (
      string: "foo",
      expect: { @Sendable in
        #expect($0.isReqular)
        #expect($0.attribute == "foo")
        #expect($0.sectionIndex == nil)
      }
    ),
    (
      string: "foo*",
      expect: { @Sendable in
        #expect($0.isExtended)
        #expect($0.attribute == "foo")
        #expect($0.sectionIndex == nil)
      }
    ),
    (
      string: "bar*0",
      expect: { @Sendable in
        #expect($0.isReqular)
        #expect($0.attribute == "bar")
        #expect($0.sectionIndex == 0)
      }
    ),

    (
      string: "bar*1*",
      expect: { @Sendable in
        #expect($0.isExtended)
        #expect($0.attribute == "bar")
        #expect($0.sectionIndex == 1)
      }
    ),
  ]

  static let nameParserTestPairsForHTTPOnly: Array<NameParserTestPair> = [
    (
      string: "foo-bar***baz",
      expect: { @Sendable in
        #expect($0.isReqular)
        #expect($0.attribute == "foo-bar***baz")
        #expect($0.sectionIndex == nil)
      }
    ),
    (
      string: "foo-bar***baz*",
      expect: { @Sendable in
        #expect($0.isExtended)
        #expect($0.attribute == "foo-bar***baz")
        #expect($0.sectionIndex == nil)
      }
    ),
    (
      string: "foo-bar*0*1*baz*0",
      expect: { @Sendable in
        #expect($0.isReqular)
        #expect($0.attribute == "foo-bar*0*1*baz")
        #expect($0.sectionIndex == 0)
      }
    ),
    (
      string: "foo-bar*0*1*baz*1*",
      expect: { @Sendable in
        #expect($0.isExtended)
        #expect($0.attribute == "foo-bar*0*1*baz")
        #expect($0.sectionIndex == 1)
      }
    ),
  ]

  @Test(
    "MIMECompatibleParameterNameParser Tests.",
    arguments: nameParserTestPairs
  )
  func test_MIMECompatibleParameterNameParser(pair: NameParserTestPair) throws {
    let name = try #require(_MIMECompatibleParameterNameParser.parse(pair.string)).output
    try pair.expect(name)
  }

  @Test(
    "HTTPHeaderFieldParameterNameParser Tests.",
    arguments: nameParserTestPairs + nameParserTestPairsForHTTPOnly
  )
  func test_HTTPHeaderFieldParameterNameParser(pair: NameParserTestPair) throws {
    let name = try #require(_HTTPHeaderFieldParameterNameParser.parse(pair.string)).output
    try pair.expect(name)
  }

  @Test(
    "Test: HTTPHeaderFieldParameter.Name Analyzer",
    arguments: Array<(string: String, expected: (attribute: ASCIICaseInsensitiveString, sectionIndex: Int?))>([
      (string: "foo", expected: (attribute: "foo"._caseInsensitive, sectionIndex: nil)),
      (string: "bar*0", expected: (attribute: "bar"._caseInsensitive, sectionIndex: 0)),
      (string: "bar*123", expected: (attribute: "bar"._caseInsensitive, sectionIndex: 123)),
      (string: "baz123", expected: (attribute: "baz123"._caseInsensitive, sectionIndex: nil)),
    ])
  )
  func test_name_analyzing(pair: (string: String, expected: (attribute: ASCIICaseInsensitiveString, sectionIndex: Int?))) throws {
    let name = HTTPHeaderFieldParameter.Name(_analyzing: pair.string.utf8)
    #expect(name.attribute == pair.expected.attribute)
    #expect(name.sectionIndex == pair.expected.sectionIndex)
  }

  @Test func test_value() throws {
    #expect(try #require(HTTPHeaderFieldParameter.Value("token-value")).description == "token-value")
    #expect(try #require(HTTPHeaderFieldParameter.Value(#""quoted value""#)).description == #""quoted value""#)
  }

  @Test func test_extendedValue() throws {
    let value1 = try #require(HTTPHeaderFieldParameter.ExtendedValue("UTF-8''%c2%a3%20and%20%e2%82%ac%20rates"))
    #expect(value1 == HTTPHeaderFieldParameter.ExtendedValue(_validated: (
      "UTF-8", nil, PercentEncodedString(encodedString: "%c2%a3%20and%20%e2%82%ac%20rates")
    )))
    #expect(value1.stringEncoding == .utf8)
    #expect(value1.decodedValue == "£ and € rates")

    let value2 = try #require(HTTPHeaderFieldParameter.ExtendedValue("utf-8'en'%C2%A3%20rates"))
    #expect(value2 == HTTPHeaderFieldParameter.ExtendedValue(_validated: (
      "utf-8",
      try #require(LanguageTagString("en")) as LanguageTagString,
      PercentEncodedString(encodedString: "%C2%A3%20rates")
    )))
    #expect(value2.stringEncoding == .utf8)
    #expect(value2.locale?.language.languageCode?.identifier == "en")
    #expect(value2.decodedValue == "£ rates")
  }


  typealias ParamterParserTestPair = (
    string: String,
    expect: @Sendable (HTTPHeaderFieldParameter?) throws -> Void
  )
  @Test(arguments: [
    (string: "foo", expect: { @Sendable in #expect($0.isNil) }),
    (string: "foo=", expect: { @Sendable in #expect($0.isNil) }),
    (
      string: "foo=bar",
      expect: { @Sendable in
        let parameter = try #require($0)
        #expect(!parameter.isExtended)
        #expect(parameter.attribute == "foo")
        #expect(parameter.sectionIndex == nil)
        #expect(parameter.value == "bar")
      }
    ),
    (
      string: #"foo="bar"#,
      expect: { @Sendable in #expect($0.isNil) }
    ),
    (
      string: #"foo="bar""#,
      expect: { @Sendable in
        let parameter = try #require($0)
        #expect(!parameter.isExtended)
        #expect(parameter.attribute == "foo")
        #expect(parameter.sectionIndex == nil)
        #expect(parameter.value == "bar")
      }
    ),
    (
      string: "foo*=utf-8''bar",
      expect: { @Sendable in
        let parameter = try #require($0)
        #expect(parameter.isExtended)
        #expect(parameter.attribute == "foo")
        #expect(parameter.sectionIndex == nil)
        #expect(parameter.value == "bar")
      }
    ),
  ] as Array<ParamterParserTestPair>)
  func test_initialization(pair: ParamterParserTestPair) throws {
    try pair.expect(HTTPHeaderFieldParameter(pair.string))
  }
}
