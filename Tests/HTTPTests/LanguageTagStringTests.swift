/* *************************************************************************************************
 LanguageTagStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct LanguageTagStringTests {
  @Test func test_PrivateUseTag_parsing() throws {
    #expect(LanguageTagString.PrivateUseTag("x").isNil)
    #expect(LanguageTagString.PrivateUseTag("x-").isNil)
    #expect(!LanguageTagString.PrivateUseTag("x-foo").isNil)
    #expect(LanguageTagString.PrivateUseTag("x-foo-").isNil)
    #expect(!LanguageTagString.PrivateUseTag("x-foo-bar").isNil)
  }

  @Test func test_GrandfatheredTag() throws {
    #expect(LanguageTagString.GrandfatheredTag("foo").isNil)
    #expect(!LanguageTagString.GrandfatheredTag("en-GB-oed").isNil)
    #expect(!LanguageTagString.GrandfatheredTag("ZH-Xiang").isNil)
  }
}
