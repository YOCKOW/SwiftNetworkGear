/* *************************************************************************************************
 LanguageTagStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct LanguageTagStringTests {
  @Test func test_Script_parsing() throws {
    #expect(LanguageTagString.Script("Japan").isNil)
    #expect(!LanguageTagString.Script("Jpan").isNil)
  }

  @Test func test_Region_parsing() throws {
    #expect(LanguageTagString.Region("Japan").isNil)
    #expect(!LanguageTagString.Region("JP").isNil)
    #expect(LanguageTagString.Region("0392").isNil)
    #expect(!LanguageTagString.Region("392").isNil)
  }

  @Test func test_Variant_parsing() throws {
    #expect(LanguageTagString.Variant("tag").isNil)
    #expect(!LanguageTagString.Variant("Variant").isNil)
    #expect(LanguageTagString.Variant("tag0").isNil)
    #expect(!LanguageTagString.Variant("0tag").isNil)
  }

  @Test func test_Extension_parsing() throws {
    #expect(LanguageTagString.Extension("y").isNil)
    #expect(LanguageTagString.Extension("w-").isNil)
    #expect(LanguageTagString.Extension("z-y").isNil)
    #expect(!LanguageTagString.Extension("z-foo").isNil)
    #expect(LanguageTagString.Extension("a-foo-").isNil)
    #expect(!LanguageTagString.Extension("b-foo-bar").isNil)
  }

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
