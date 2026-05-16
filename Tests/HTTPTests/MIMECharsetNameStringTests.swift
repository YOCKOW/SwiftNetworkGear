/* *************************************************************************************************
 MIMECharsetNameStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite final class MIMECharsetNameStringTests {
  @Test func test_name() throws {
    #expect(try #require(MIMECharsetNameString(encoding: .utf8)).name.isASCIICaseInsensitivelyEqual(to: "UTF-8"))
    #expect(MIMECharsetNameString(name: "", isUsedInExtendedParameterValue: false).isNil)
    #expect(MIMECharsetNameString(name: "u 8", isUsedInExtendedParameterValue: false).isNil)
  }
}
