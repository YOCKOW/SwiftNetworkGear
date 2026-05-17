/* *************************************************************************************************
 LanguageTagStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct LanguageTagStringTests {
  @Test func test_PrivateUse_parsing() throws {
    #expect(LanguageTagString.PrivateUse("x").isNil)
    #expect(LanguageTagString.PrivateUse("x-").isNil)
    #expect(!LanguageTagString.PrivateUse("x-foo").isNil)
    #expect(LanguageTagString.PrivateUse("x-foo-").isNil)
    #expect(!LanguageTagString.PrivateUse("x-foo-bar").isNil)
  }
}
