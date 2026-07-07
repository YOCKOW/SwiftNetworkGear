/* *************************************************************************************************
 LanguageTagStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing
import yExtensions

private protocol _LanguageSubtag {}

typealias Language = LanguageTagString.Language
typealias Script = LanguageTagString.Script
typealias Region = LanguageTagString.Region
typealias Variant = LanguageTagString.Variant
typealias Extension = LanguageTagString.Extension
typealias Singleton = LanguageTagString.Extension.Singleton
typealias PrivateUseTag = LanguageTagString.PrivateUseTag
typealias GrandfatheredTag = LanguageTagString.GrandfatheredTag

extension Language: _LanguageSubtag {}
extension Script: _LanguageSubtag {}
extension Region: _LanguageSubtag {}
extension Variant: _LanguageSubtag {}
extension Extension: _LanguageSubtag {}
extension PrivateUseTag: _LanguageSubtag {}
extension GrandfatheredTag: _LanguageSubtag {}

// Workaround for https://github.com/swiftlang/swift-testing/issues/1724
private func _require<T>(
  _ subtag: T?,
  _ comment: @autoclosure () -> Comment? = nil,
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> T where T: _LanguageSubtag {
  return try #require(subtag, comment(), sourceLocation: sourceLocation)
}

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
      invalidString("ABC-DEFG", for: LanguageTagString.Language.ExtendedLanguage.self)

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

    let extA = try #require(Extension("a-foo-bar"))
    let extB = try #require(Extension("b-foo-bar"))
    #expect(extA.description == "a-foo-bar")
    #expect(extB.description == "b-foo-bar")
    #expect(extA.singleton != extB.singleton)
    #expect(extA.singleton == Singleton("A"))
    #expect(extB.singleton == Singleton("B"))
    #expect(extA.values.count == 2)
    #expect(extB.values.count == 2)
    #expect(extA.values.first == Extension.Value("foo"))
    #expect(extA.values.last == Extension.Value("bar"))
    #expect(extA.values == extB.values)
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

  @Test(
    "`LanguageTagString` Parser Tests",
    arguments: Array<(string: String, expect: @Sendable () throws -> LanguageTagString?)>([
      // https://datatracker.ietf.org/doc/html/rfc5646#appendix-A

      // MARK: Simple language subtag
      (
        "de",
        { @Sendable in
          LanguageTagString(language: try _require(Language("de")))
        }
      ),
      (
        "fr",
        { @Sendable in
          LanguageTagString(language: try _require(Language("FR")))
        }
      ),
      (
        "ja",
        { @Sendable in
          LanguageTagString(language: try _require(Language("ja")))
        }
      ),
      (
        "i-enochian",
        { @Sendable in
          LanguageTagString(grandfatheredTag: try _require(GrandfatheredTag("i-enochian")))
        }
      ),

      // MARK: Language subtag plus Script subtag
      (
        "zh-Hant",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("zh")),
            script: _require(Script("hant"))
          )
        }
      ),
      (
        "zh-Hans",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("zh")),
            script: _require(Script("Hans"))
          )
        }
      ),
      (
        "sr-Cyrl",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sr")),
            script: _require(Script("Cyrl"))
          )
        }
      ),
      (
        "sr-Latn",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sr")),
            script: _require(Script("Latn"))
          )
        }
      ),

      // MARK: Extended language subtags and their primary language subtag counterparts
      (
        "zh-cmn-Hans-CN",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("zh-cmn")),
            script: _require(Script("hans")),
            region: _require(Region("cn"))
          )
        }
      ),
      (
        "cmn-Hans-CN",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("cmn")),
            script: _require(Script("hans")),
            region: _require(Region("cn"))
          )
        }
      ),
      (
        "zh-yue-HK",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("zh-yue")),
            region: _require(Region("hk"))
          )
        }
      ),
      (
        "yue-HK",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("yue")),
            region: _require(Region("hk"))
          )
        }
      ),

      // MARK: Language-Script-Region
      (
        "zh-Hans-CN",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("zh")),
            script: _require(Script("hans")),
            region: _require(Region("cn"))
          )
        }
      ),
      (
        "sr-Latn-RS",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sr")),
            script: _require(Script("latn")),
            region: _require(Region("rs"))
          )
        }
      ),

      // MARK: Language-Variant
      (
        "sl-rozaj",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sl")),
            variants: [
              _require(Variant("rozaj")),
            ]
          )
        }
      ),
      (
        "sl-rozaj-biske",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sl")),
            variants: [
              _require(Variant("rozaj")),
              _require(Variant("biske")),
            ]
          )
        }
      ),
      (
        "sl-nedis",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sl")),
            variants: [
              _require(Variant("nedis")),
            ]
          )
        }
      ),

      // MARK: Language-Region-Variant
      (
        "de-CH-1901",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("de")),
            region: _require(Region("ch")),
            variants: [
              _require(Variant("1901")),
            ]
          )
        }
      ),
      (
        "sl-IT-nedis",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sl")),
            region: _require(Region("it")),
            variants: [
              _require(Variant("nedis")),
            ]
          )
        }
      ),

      // MARK: Language-Script-Region-Variant
      (
        "hy-Latn-IT-arevela",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("hy")),
            script: _require(Script("latn")),
            region: _require(Region("it")),
            variants: [
              _require(Variant("arevela")),
            ]
          )
        }
      ),

      // MARK: Language-Region
      (
        "de-DE",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("de")),
            region: _require(Region("de")),
          )
        }
      ),
      (
        "en-US",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("en")),
            region: _require(Region("us")),
          )
        }
      ),
      (
        "es-419",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("es")),
            region: _require(Region("419")),
          )
        }
      ),

      // MARK: Private use subtags
      (
        "de-CH-x-phonebk",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("de")),
            region: _require(Region("ch")),
            privateUseTag: _require(PrivateUseTag("x-phonebk"))
          )
        }
      ),
      (
        "az-Arab-x-AZE-derbend",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("az")),
            script: _require(Script("arab")),
            privateUseTag: _require(PrivateUseTag("x-aze-derbend"))
          )
        }
      ),

      // MARK: Private use registry values
      (
        "x-whatever",
        { @Sendable in
          try LanguageTagString(
            privateUseTag: _require(PrivateUseTag("x-whatever"))
          )
        }
      ),
      (
        "qaa-Qaaa-QM-x-southern",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("qaa")),
            script: _require(Script("qaaa")),
            region: _require(Region("qm")),
            privateUseTag: _require(PrivateUseTag("x-southern"))
          )
        }
      ),
      (
        "de-Qaaa",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("de")),
            script: _require(Script("qaaa"))
          )
        }
      ),
      (
        "sr-Latn-QM",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sr")),
            script: _require(Script("latn")),
            region: _require(Region("qm"))
          )
        }
      ),
      (
        "sr-Qaaa-RS",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("sr")),
            script: _require(Script("qaaa")),
            region: _require(Region("rs"))
          )
        }
      ),

      // MARK: Tags that use extensions
      (
        "en-US-u-islamcal",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("en")),
            region: _require(Region("us")),
            extensions: [
              _require(Extension("u-islamcal")),
            ]
          )
        }
      ),
      (
        "zh-CN-a-myext-x-private",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("zh")),
            region: _require(Region("cn")),
            extensions: [
              _require(Extension("a-myext")),
            ],
            privateUseTag: _require(PrivateUseTag("x-private"))
          )
        }
      ),
      (
        "en-a-myext-b-another",
        { @Sendable in
          try LanguageTagString(
            language: _require(Language("en")),
            extensions: [
              _require(Extension("a-myext")),
              _require(Extension("b-another")),
            ]
          )
        }
      ),

      // MARK: Some Invalid Tags
      ("de-419-DE", { @Sendable in nil } as @Sendable () throws -> LanguageTagString?),
      ("a-DE", { @Sendable in nil } as @Sendable () throws -> LanguageTagString?),
      ("ar-a-aaa-b-bbb-a-ccc", { @Sendable in nil } as @Sendable () throws -> LanguageTagString?),
    ])
  )
  func test_parsing(pair: (string: String, expect: @Sendable () throws -> LanguageTagString?)) throws {
    let created = LanguageTagString(pair.string)
    if let expected = try pair.expect() {
      #expect(created == created)
      #expect(expected == expected)
      #expect(created == expected)
      #expect(pair.string._caseInsensitive == expected.description._caseInsensitive)
    } else {
      #expect(created.isNil)
    }
  }

  @Test func test_canonicalizedExtensions() throws {
    let noncanonicalDescription = "ja-0-000-c-ccc-B-BBB-D-DDD-a-aaa"
    let created = try #require(LanguageTagString(noncanonicalDescription))
    #expect(try created.language == _require(Language("ja")))
    #expect(try #require(created.extensions).extensions == [
      #require(Extension("0-000")),
      #require(Extension("a-aaa")),
      #require(Extension("b-bbb")),
      #require(Extension("c-ccc")),
      #require(Extension("d-ddd")),
    ])
    #expect(created.description == "ja-0-000-a-aaa-B-BBB-c-ccc-D-DDD")
  }
}
