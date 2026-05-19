/* *************************************************************************************************
 LanguageTagStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing
import yExtensions

@Suite struct LanguageTagStringTests {
  func validString<L>(
    _ string: String,
    for type: L.Type,
    _ comment: @autoclosure () -> Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
  ) where L: LosslessStringConvertible {
    #expect(!L(string).isNil, comment(), sourceLocation: sourceLocation)
  }

  func invalidString<L>(
    _ string: String,
    for type: L.Type,
    _ comment: @autoclosure () -> Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
  ) where L: LosslessStringConvertible {
    #expect(L(string).isNil, comment(), sourceLocation: sourceLocation)
  }

  @Test func test_Language_ExtendedLanguage_parsing() throws {
    EXT: do {
      invalidString("A", for: LanguageTagString.Language.ExtendedLanguage.self)
      invalidString("AB", for: LanguageTagString.Language.ExtendedLanguage.self)
      validString("ABC", for: LanguageTagString.Language.ExtendedLanguage.self)

      invalidString("ABC-D", for: LanguageTagString.Language.ExtendedLanguage.self)
      validString("ABC-DEF", for: LanguageTagString.Language.ExtendedLanguage.self)

      invalidString("ABC-DEF-", for: LanguageTagString.Language.ExtendedLanguage.self)
      invalidString("ABC-DEF-G", for: LanguageTagString.Language.ExtendedLanguage.self)
      validString("ABC-DEF-GHI", for: LanguageTagString.Language.ExtendedLanguage.self)

      invalidString("ABC-DEF-GHI-", for: LanguageTagString.Language.ExtendedLanguage.self)
      invalidString("ABC-DEF-GHI-J", for: LanguageTagString.Language.ExtendedLanguage.self)
      invalidString("ABC-DEF-GHI-JKL", for: LanguageTagString.Language.ExtendedLanguage.self)
    }

    LANG: do {
      invalidString("A", for: LanguageTagString.Language.self)
      validString("ja", for: LanguageTagString.Language.self)
      invalidString("longLongLanguage", for: LanguageTagString.Language.self)

      validString("abc-ext-ext-ext", for: LanguageTagString.Language.self)
      invalidString("abc-ext-ext-extension", for: LanguageTagString.Language.self)
      invalidString("abc-ext-ext-ext-", for: LanguageTagString.Language.self)
    }
  }

  @Test func test_Script_parsing() throws {
    invalidString("Japan", for: LanguageTagString.Script.self)
    validString("Jpan", for: LanguageTagString.Script.self)
  }

  @Test func test_Region_parsing() throws {
    invalidString("Japan", for: LanguageTagString.Region.self)
    validString("JP", for: LanguageTagString.Region.self)
    invalidString("0392", for: LanguageTagString.Region.self)
    validString("392", for: LanguageTagString.Region.self)
  }

  @Test func test_Variant_parsing() throws {
    invalidString("tag", for: LanguageTagString.Variant.self)
    validString("Variant", for: LanguageTagString.Variant.self)
    invalidString("tag0", for: LanguageTagString.Variant.self)
    validString("0tag", for: LanguageTagString.Variant.self)
  }

  @Test func test_Extension_parsing() throws {
    invalidString("y", for: LanguageTagString.Extension.self)
    invalidString("w-", for: LanguageTagString.Extension.self)
    invalidString("z-y", for: LanguageTagString.Extension.self)
    validString("z-foo", for: LanguageTagString.Extension.self)
    invalidString("a-foo-", for: LanguageTagString.Extension.self)
    validString("b-foo-bar", for: LanguageTagString.Extension.self)
  }

  @Test func test_PrivateUseTag_parsing() throws {
    invalidString("x", for: LanguageTagString.PrivateUseTag.self)
    invalidString("x-", for: LanguageTagString.PrivateUseTag.self)
    validString("x-foo", for: LanguageTagString.PrivateUseTag.self)
    invalidString("x-foo-", for: LanguageTagString.PrivateUseTag.self)
    validString("x-foo-bar", for: LanguageTagString.PrivateUseTag.self)
  }

  @Test func test_GrandfatheredTag() throws {
    invalidString("foo", for: LanguageTagString.GrandfatheredTag.self)
    validString("en-GB-oed", for: LanguageTagString.GrandfatheredTag.self)
    validString("ZH-Xiang", for: LanguageTagString.GrandfatheredTag.self)
  }
}
