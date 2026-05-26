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
}
