/* *************************************************************************************************
 HTTPHeaderFieldParameterTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
@testable import NetworkGear
import Testing
import yExtensions

private func _regularName<S>(
  _ string: S,
  sectionIndex: Int? = nil,
  _ comment: @autoclosure () -> Comment? = nil,
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> HTTPHeaderFieldParameter.Name where S: StringProtocol {
  return try #require(
    HTTPHeaderFieldParameter.Name(attribute: string, sectionIndex: sectionIndex),
    comment(),
    sourceLocation: sourceLocation
  )
}

private func _extendedName<S>(
  _ string: S,
  sectionIndex: Int? = nil,
  _ comment: @autoclosure () -> Comment? = nil,
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> HTTPHeaderFieldParameter.ExtendedName where S: StringProtocol {
  return try #require(
    HTTPHeaderFieldParameter.ExtendedName(attribute: string, sectionIndex: sectionIndex),
    comment(),
    sourceLocation: sourceLocation
  )
}

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
    let tokenValue = try #require(HTTPHeaderFieldParameter.Value("token-value"))
    let quotedValue = try #require(HTTPHeaderFieldParameter.Value(#""quoted value""#))

    #expect(tokenValue.description == "token-value")
    #expect(quotedValue.description == #""quoted value""#)

    division_test: do {
      func __assert(
        value: HTTPHeaderFieldParameter.Value,
        divisionCount count: Int,
        expected: (firstPart: String, secondPart: String?),
        _ comment: @autoclosure () -> Comment? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
      ) {
        let divided = value.divide(whereFirstPartMaxUTF8Count: count)
        #expect(
          divided.0.description.utf8.count <= count,
          Comment(rawValue: "[Count] " + (comment()?.rawValue ?? "")),
          sourceLocation: sourceLocation
        )
        #expect(
          divided.0.description == expected.firstPart,
          Comment(rawValue: "[First Part] " + (comment()?.rawValue ?? "")),
          sourceLocation: sourceLocation
        )
        #expect(
          divided.1?.description == expected.secondPart,
          Comment(rawValue: "[Second Part] " + (comment()?.rawValue ?? "")),
          sourceLocation: sourceLocation
        )
      }

      __assert(value: tokenValue, divisionCount: 99, expected: ("token-value", nil))
      __assert(value: tokenValue, divisionCount: 11, expected: ("token-value", nil))
      __assert(value: tokenValue, divisionCount: 10, expected: ("token-valu", "e"))
      __assert(value: tokenValue, divisionCount:  9, expected: ("token-val", "ue"))
      __assert(value: tokenValue, divisionCount:  5, expected: ("token", "-value"))

      __assert(value: quotedValue, divisionCount: 99, expected: (#""quoted value""#, nil))
      __assert(value: quotedValue, divisionCount: 14, expected: (#""quoted value""#, nil))
      __assert(value: quotedValue, divisionCount: 13, expected: (#""quoted valu""#, #""e""#))
      __assert(value: quotedValue, divisionCount:  8, expected: (#""quoted""#, #"" value""#))
    }
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

    division_test: do {
      func __assert(
        value: HTTPHeaderFieldParameter.ExtendedValue,
        divisionCount: Int,
        expected: (firstPart: String, secondPart: String?)?,
        sourceLocation: SourceLocation = #_sourceLocation
      ) throws {
        guard let divided = value.divide(whereFirstPartMaxUTF8Count: divisionCount) else {
          #expect(expected.isNil, "Division must fail.", sourceLocation: sourceLocation)
          return
        }
        guard let expected = expected else {
          Issue.record("`expected` must not be nil.", sourceLocation: sourceLocation)
          return
        }
        let expectedFirstPart = try #require(
          HTTPHeaderFieldParameter.ExtendedValue(expected.firstPart),
          "Create Expected First Part",
          sourceLocation: sourceLocation
        )
        let expectedSecondPart = try expected.secondPart.map({
          try #require(
            HTTPHeaderFieldParameter.InformationlessExtendedValue($0),
            "Create Expected Second Part",
            sourceLocation: sourceLocation
          )
        })
        #expect(divided.0 == expectedFirstPart, "First Part", sourceLocation: sourceLocation)
        #expect(divided.1 == expectedSecondPart, "Second Part", sourceLocation: sourceLocation)
      }

      try __assert(
        value: value1,
        divisionCount: 99,
        expected: ("UTF-8''%c2%a3%20and%20%e2%82%ac%20rates", nil)
      )
      try __assert(
        value: value1,
        divisionCount: 39,
        expected: ("UTF-8''%c2%a3%20and%20%e2%82%ac%20rates", nil)
      )
      try __assert(
        value: value1,
        divisionCount: 38,
        expected: ("UTF-8''%c2%a3%20and%20%e2%82%ac%20rate", "s")
      )
      try __assert(
        value: value1,
        divisionCount: 34,
        expected: ("UTF-8''%c2%a3%20and%20%e2%82%ac%20", "rates")
      )
      try __assert(
        value: value1,
        divisionCount: 33,
        expected: ("UTF-8''%c2%a3%20and%20%e2%82%ac", "%20rates")
      )
      try __assert(
        value: value1,
        divisionCount: 31,
        expected: ("UTF-8''%c2%a3%20and%20%e2%82%ac", "%20rates")
      )
      try __assert(
        value: value1,
        divisionCount: 30,
        expected: ("UTF-8''%c2%a3%20and%20%e2%82", "%ac%20rates")
      )
      try __assert(
        value: value1,
        divisionCount: 9,
        expected: nil
      )

      try __assert(
        value: value2,
        divisionCount: 99,
        expected: ("utf-8'en'%C2%A3%20rates", nil)
      )
      try __assert(
        value: value2,
        divisionCount: 23,
        expected: ("utf-8'en'%C2%A3%20rates", nil)
      )
      try __assert(
        value: value2,
        divisionCount: 18,
        expected: ("utf-8'en'%C2%A3%20", "rates")
      )
      try __assert(
        value: value2,
        divisionCount: 17,
        expected: ("utf-8'en'%C2%A3", "%20rates")
      )
      try __assert(
        value: value2,
        divisionCount: 11,
        expected: nil
      )
    }
  }

  @Test func test_name_value_initializers() {
    #expect(
      HTTPHeaderFieldParameter.Name(attribute: "foo", sectionIndex: 0)?.description ==
      "foo*0"
    )
    #expect(
      HTTPHeaderFieldParameter.ExtendedName(attribute: "bar", sectionIndex: 1)?.description ==
      "bar*1*"
    )
    #expect(HTTPHeaderFieldParameter.Value(quoting: "foo")?.description == #""foo""#)
    #expect(
      HTTPHeaderFieldParameter.ExtendedValue(
        addingPercentEncodingToValue: "£ rates"
      ).description.isASCIICaseInsensitivelyEqual(
        to: #"utf-8''%C2%A3%20rates"#
      )
    )
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

  @Test func test_listParser() throws {
    let CRLF = "\u{0D}\u{0A}"
    do {
      let string = "filename=\"my-file.txt\"; \(CRLF)  filename*=UTF-8''%E7%A7%81%E3%81%AE%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt;\(CRLF)  my-parameter*0=zero; my-parameter*1=\"-one\";"
      let list = try #require(HTTPHeaderFieldParameterList(string))

      #expect(list["filename"]?.value == "私のファイル.txt")
      #expect(list["my-parameter", sectionIndex: 0]?.value == "zero")
      #expect(list["my-parameter", sectionIndex: 1]?.value == "-one")
      #expect(list.combinedValue(for: "my-parameter") == "zero-one")
    }

    do {
      let string = "title*0*=us-ascii'en'This%20is%20even%20more%20;\(CRLF) title*1*=%2A%2A%2Afun%2A%2A%2A%20;\(CRLF) title*2=\"isn't it!\""
      let list = try #require(HTTPHeaderFieldParameterList(string))

      #expect(list["title"].isNil)
      #expect(list["title", sectionIndex: 0]?.isExtended == true)
      #expect(list["title", sectionIndex: 0]?.extendedValue.isNil == false)
      #expect(list["title", sectionIndex: 0]?.value == "This is even more ")

      #expect(list["title", sectionIndex: 1]?.isExtended == true)
      #expect(list["title", sectionIndex: 1]?.informationlessExtendedValue.isNil == false)
      #expect(list["title", sectionIndex: 1]?.value == "***fun*** ")

      #expect(list["title", sectionIndex: 2]?.isExtended == false)
      #expect(list["title", sectionIndex: 2]?.regularValue.isNil == false)
      #expect(list["title", sectionIndex: 2]?.value == "isn't it!")

      #expect(list.combinedValue(for: "title") == "This is even more ***fun*** isn't it!")
    }
  }

  @Test func test_fixForHTTP() throws {
    Test_Fast_Path: do {
      let list = try #require(HTTPHeaderFieldParameterList("a=regular; a*=UTF-8''extended"))
      let fixed = try #require(list.fixed(for: .http))
      #expect(fixed.allParameters.count == 2)
      #expect(fixed["a"]?.value == "extended")
      #expect(fixed[try _regularName("a")]?.content == "regular")
    }


    let listString = """
    p1-1="v1-1-regular"; p1-1*=UTF-8''v1%2D1%2Dextended;
    p1-2="v1-2-regular";
    p1-3*=UTF-8''v1%2D3%2Dextended;
    p2-1="v2-1-regular"; p2-1*=UTF-8''v2%2d1%2dextended;
      p2-1*0="v2-1-0"; p2-1*1="-v2-1-1";
    p2-2="v2-2-regular"; p2-2*=UTF-8''v2%2d2%2dextended;
      p2-2*0*=UTF-8''v2%2d2%2d0; p2-2*1="-v2-2-1";
    p3-1="v3-1-regular";
      p3-1*0="v3-1-0"; p3-1*1="-v3-1-1";
    p3-2="v3-2-regular";
      p3-2*0*=UTF-8''v3%2d2%2d0; p3-2*1*=%2dv3%2d2%2d1; p3-2*2="-v3-2-2";
    p4*=us-ascii''v4%2dextended;
      p4*0="v4-0"; p4*1="-v4-1";
    p5-a*=shift_jis''v5%2da%2dextended%2dto%2dregular;
      p5-a*0*=shift_jis''v5%2da%2d0%2d%8Ag%92%A3; p5-a*1*=%2dv5%2da%2d1%2d%8Ag%92%A3;
    p5-b*=UTF-8''v5%2Db%2D%E6%8B%A1%E5%BC%B5;
      p5-b*0*=UTF-8''v5%2Db%2D0; p5-b*1*=%2Dv5%2Db%2D1;
    p5-c*=UTF-8''v5%2Dc%2Dnon%2Dsectioned%2D%E6%8B%A1%E5%BC%B5;
      p5-c*0*=UTF-8''v5%2Dc%2D0; p5-c*1*=%2Dv5%2Dc%2D1%2D%E6%8B%A1%E5%BC%B5;
    p6*0*=UTF-8''v6%2D0; p6*1*=%2Dv6%2D1; p6*2="-v6-2";
    """.split(
      omittingEmptySubsequences: true,
      whereSeparator: { $0.isWhitespace || $0.isNewline }
    ).joined(separator: " ")
    let list = try #require(HTTPHeaderFieldParameterList(listString))
    let fixed = try #require(list.fixed(for: .http))

    func __test(
      _ attribute: String,
      regular expectedRegularValue: String?,
      extended expectedExtendedValue: String?,
      _ comment: @autoclosure () -> Comment? = nil,
      sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
      let regularName = try _regularName(attribute, comment(), sourceLocation: sourceLocation)
      let extendedName = try _extendedName(attribute, comment(), sourceLocation: sourceLocation)
      #expect(
        fixed[regularName]?.content == expectedRegularValue,
        Comment(rawValue: "[Regular Value for '\(attribute)'] " + (comment()?.rawValue ?? "")),
        sourceLocation: sourceLocation
      )
      #expect(
        fixed[extendedName]?.decodedValue == expectedExtendedValue,
        Comment(rawValue: "[Extended Value for '\(attribute)'] " + (comment()?.rawValue ?? "")),
        sourceLocation: sourceLocation
      )

      let caseInsensitiveAttribute = ASCIICaseInsensitiveString(attribute)
      let expectedDefaultValue: String? = expectedExtendedValue ?? expectedRegularValue
      #expect(
        fixed[caseInsensitiveAttribute]?.value == expectedDefaultValue,
        Comment(rawValue: "[Default Value for '\(attribute)'] " + (comment()?.rawValue ?? "")),
        sourceLocation: sourceLocation
      )
    }

    try __test("foo", regular: nil, extended: nil)
    try __test("p1-1", regular: "v1-1-regular", extended: "v1-1-extended")
    try __test("p1-2", regular: "v1-2-regular", extended: nil)
    try __test("p1-3", regular: nil, extended: "v1-3-extended")
    try __test("p2-1", regular: "v2-1-regular", extended: "v2-1-extended")
    try __test("p2-2", regular: "v2-2-regular", extended: "v2-2-extended")
    try __test("p3-1", regular: "v3-1-regular", extended: "v3-1-0-v3-1-1")
    try __test("p3-2", regular: "v3-2-regular", extended: "v3-2-0-v3-2-1-v3-2-2")
    try __test("p4", regular: "v4-0-v4-1", extended: "v4-extended")
    try __test("p5-a", regular: "v5-a-extended-to-regular", extended: "v5-a-0-拡張-v5-a-1-拡張")
    try __test("p5-b", regular: "v5-b-0-v5-b-1", extended: "v5-b-拡張")
    try __test("p5-c", regular: nil, extended: "v5-c-non-sectioned-拡張")
    try __test("p6", regular: "v6-0-v6-1-v6-2", extended: "v6-0-v6-1-v6-2")
  }
}
