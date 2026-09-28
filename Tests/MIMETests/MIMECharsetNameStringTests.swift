/* *************************************************************************************************
 MIMECharsetNameStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing
import yExtensions

@Suite final class MIMECharsetNameStringTests {
  @Test func test_name() throws {
    #expect(
      try #require(MIMECharsetNameString(encoding: .utf8)) ==
      #require(MIMECharsetNameString(name: "UTF-8", isUsedInExtendedParameterValue: true))
    )
    #expect(MIMECharsetNameString(name: "", isUsedInExtendedParameterValue: false).isNil)
    #expect(MIMECharsetNameString(name: "u 8", isUsedInExtendedParameterValue: false).isNil)
  }

  @Test func test_equatable() throws {
    #expect(
      try #require(MIMECharsetNameString(name: "UTF-8", isUsedInExtendedParameterValue: false)) ==
      #require(MIMECharsetNameString(name: "uTf-8", isUsedInExtendedParameterValue: true))
    )
  }

  @Test func test_hashable() throws {
    var dict: [MIMECharsetNameString: Int] = [:]
    #expect(dict.updateValue(1, forKey: try #require(MIMECharsetNameString(name: "euc-jp", isUsedInExtendedParameterValue: true))).isNil)
    #expect(dict.updateValue(2, forKey: try #require(MIMECharsetNameString(name: "EUC-JP", isUsedInExtendedParameterValue: true))) == 1)
    #expect(dict.updateValue(3, forKey: try #require(MIMECharsetNameString(name: "eUc-jP", isUsedInExtendedParameterValue: true))) == 2)
    #expect(dict[try #require(MIMECharsetNameString(name: "euc-jp", isUsedInExtendedParameterValue: false))] == 3)
  }
}
