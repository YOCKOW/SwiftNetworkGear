/* *************************************************************************************************
 LanguageTagString.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

private extension Unicode.UTF8.CodeUnit {
  var _isSingleton: Bool {
    if _isDigit {
      return true
    }
    switch self {
    case 0x41...0x57, 0x59, 0x5A, // A-W, Y, Z
         0x61...0x77, 0x79, 0x7A: // a-w, y, z
      return true
    default:
      return false
    }
  }
}

private struct _HyphenFollowedBy<FollowerParser, Input>: StringParser, _UTF8Parser
where FollowerParser: StringParser,
      FollowerParser.Input == Input.SubSequence,
      Input: StringProtocol {
  typealias Output = FollowerParser.Output

  let string: Input
  let utf8: Input.UTF8View

  init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  mutating func parse() -> (output: FollowerParser.Output, endIndex: Input.Index)? {
    var index = self.utf8.startIndex
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isHyphen) else {
      return nil
    }
    return FollowerParser.parse(string[index...])
  }
}

/// A string that represents ["Language Tag"](https://datatracker.ietf.org/doc/html/rfc5646).
public struct LanguageTagString: Sendable, Equatable, Hashable, CustomStringConvertible {
  public struct Language: Sendable,
                          LosslessStringConvertible,
                          Equatable,
                          Hashable,
                          _InitializableWithParser {
    public struct ExtendedLanguage: Sendable,
                                    LosslessStringConvertible,
                                    Equatable,
                                    Hashable,
                                    _InitializableWithParser {
      private let _string: ASCIICaseInsensitiveString

      public var description: String { String(describing: _string) }

      fileprivate init(_ string: ASCIICaseInsensitiveString) {
        self._string = string
      }

      private struct _3AlphabetParser<Input>: StringParser, _UTF8Parser
      where Input: StringProtocol {
        typealias Output = Input.SubSequence

        let string: Input
        let utf8: Input.UTF8View

        init(input: Input) {
          self.string = input
          self.utf8 = input.utf8
        }

        mutating func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
          var index = self.utf8.startIndex
          guard let substring = self.parseString(
            from: &index,
            minCount: 3,
            maxCount: 3,
            while: \._isAlphabet
          ) else {
            return nil
          }
          if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
            return nil
          }
          return (substring, index)
        }
      } // _3AlphabetParser

      private final class _OneOrTwoHyphenAnd3AlphaParser<Input>: RepetitionParser<
        Input,
        _HyphenFollowedBy<_3AlphabetParser<Input.SubSequence>, Input.SubSequence>
      > where Input: StringProtocol {
        override var maxCount: Int {
          get { 2 }
          set { super.maxCount = 2 }
        }
      } // _OneOrTwoHyphenAnd3AlphaParser

      internal struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
        typealias Output = ExtendedLanguage

        let string: Input
        let utf8: Input.UTF8View

        init(input: Input) {
          self.string = input
          self.utf8 = input.utf8
        }

        mutating func parse() -> (output: ExtendedLanguage, endIndex: Input.Index)? {
          guard let first3AlphaResult = _3AlphabetParser<Input>.parse(string) else {
            return nil
          }

          func __createResult(endIndex: Input.Index) -> (ExtendedLanguage, Input.Index) {
            return (
              ExtendedLanguage(ASCIICaseInsensitiveString(String(string[..<endIndex]))),
              endIndex
            )
          }
          if let more3AlphaResult = _OneOrTwoHyphenAnd3AlphaParser<Input.SubSequence>.parse(
            string[first3AlphaResult.endIndex...]
          ) {
            return __createResult(endIndex: more3AlphaResult.endIndex)
          } else {
            var index = first3AlphaResult.endIndex
            if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
              return nil
            }
            return __createResult(endIndex: index)
          }
        }
      } // ExtendedLanguage.Parser

      public init?<S>(_ string: S) where S: StringProtocol {
        self.init(string, parser: Parser<S>.self)
      }
    } // Language.ExtendedLanguage

    private let _string: ASCIICaseInsensitiveString

    public var description: String { String(describing: _string) }

    fileprivate init(_ string: ASCIICaseInsensitiveString) {
      self._string = string
    }

    internal struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
      typealias Output = Language

      let string: Input
      let utf8: Input.UTF8View

      init(input: Input) {
        self.string = input
        self.utf8 = input.utf8
      }

      mutating func parse() -> (output: Language, endIndex: Input.Index)? {
        var index = self.utf8.startIndex
        var numberOfAlphabets = 0
        guard let _ = self.parseString(
          from: &index,
          minCount: 2,
          maxCount: 8,
          count: &numberOfAlphabets,
          while: \._isAlphabet
        ) else {
          return nil
        }

        func __createResult(endIndex: Input.Index) -> (Output, Input.Index) {
          return (Language(ASCIICaseInsensitiveString(String(string[..<endIndex]))), endIndex)
        }

        if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
          return nil
        }

        switch numberOfAlphabets {
        case 2, 3: // shortest ISO 639 code
          let shortestCodeEndIndex = index
          guard index < utf8.endIndex, utf8[index]._isHyphen else {
            return __createResult(endIndex: shortestCodeEndIndex)
          }
          utf8.formIndex(after: &index)
          guard let extlangResult = ExtendedLanguage.Parser<Input.SubSequence>.parse(
            string[index...]
          ) else {
            return __createResult(endIndex: shortestCodeEndIndex)
          }
          return __createResult(endIndex: extlangResult.endIndex)
        case 4: // reserved for future use
          return __createResult(endIndex: index)
        case 5...8: // registered language subtag
          return __createResult(endIndex: index)
        default:
          fatalError("Unexpected Distancee?!")
        }
      }
    } // Language.Parser

    public init?<S>(_ string: S) where S: StringProtocol {
      self.init(string, parser: Parser<S>.self)
    }
  } // Language

  /// A representation of `script` part.
  public struct Script: Sendable,
                        LosslessStringConvertible,
                        Equatable,
                        Hashable,
                        _InitializableWithParser {
    private let _string: ASCIICaseInsensitiveString

    public var description: String { String(describing: _string) }

    fileprivate init(_ string: ASCIICaseInsensitiveString) {
      self._string = string
    }

    internal struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
      typealias Output = Script

      let string: Input
      let utf8: Input.UTF8View

      init(input: Input) {
        self.string = input
        self.utf8 = input.utf8
      }

      mutating func parse() -> (output: Script, endIndex: Input.Index)? {
        var index = utf8.startIndex

        // ISO 15924 code
        guard let string = self.parseString(
          from: &index,
          minCount: 4,
          maxCount: 4,
          while: \._isAlphabet
        ) else {
          return nil
        }
        if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
          return nil
        }
        return (Script(ASCIICaseInsensitiveString(String(string))), index)
      }
    } // Script.Parser

    public init?<S>(_ string: S) where S: StringProtocol {
      self.init(string, parser: Parser<S>.self)
    }
  } // Script

  /// A representation of `region` part.
  public struct Region: Sendable,
                        LosslessStringConvertible,
                        Equatable,
                        Hashable,
                        _InitializableWithParser {
    private let _string: ASCIICaseInsensitiveString
    
    public var description: String { String(describing: _string) }
    
    fileprivate init(_ string: ASCIICaseInsensitiveString) {
      self._string = string
    }
    
    internal struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
      typealias Output = Region

      let string: Input
      let utf8: Input.UTF8View

      init(input: Input) {
        self.string = input
        self.utf8 = input.utf8
      }

      mutating func parse() -> (output: Region, endIndex: Input.Index)? {
        var index = utf8.startIndex

        // ISO 3166-1 code
        if let string = self.parseString(
          from: &index,
          minCount: 2,
          maxCount: 2,
          while: \._isAlphabet
        ) {
          if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
            return nil
          }
          return (Region(ASCIICaseInsensitiveString(String(string))), index)
        } else {
          // UN M.49 code
          guard let string = self.parseString(
            from: &index,
            minCount: 3,
            maxCount: 3,
            while: \._isDigit
          ) else {
            return nil
          }
          if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
            return nil
          }
          return (Region(ASCIICaseInsensitiveString(String(string))), index)
        }
      }
    } // Region.Parser

    public init?<S>(_ string: S) where S: StringProtocol {
      self.init(string, parser: Parser<S>.self)
    }
  } // Region

  /// A representation of `variant` part.
  public struct Variant: Sendable,
                         LosslessStringConvertible,
                         Equatable,
                         Hashable,
                         _InitializableWithParser {
    private let _string: ASCIICaseInsensitiveString

    public var description: String { String(describing: _string) }

    fileprivate init(_ string: ASCIICaseInsensitiveString) {
      self._string = string
    }

    internal struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
      typealias Output = Variant

      let string: Input
      let utf8: Input.UTF8View

      init(input: Input) {
        self.string = input
        self.utf8 = input.utf8
      }

      mutating func parse() -> (output: Variant, endIndex: Input.Index)? {
        var index = utf8.startIndex

        if let string = self.parseString(
          from: &index,
          minCount: 5,
          maxCount: 8,
          while: \._isAlphanumeric
        ) {
          if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
            return nil
          }
          return (Variant(ASCIICaseInsensitiveString(String(string))), index)
        } else {
          guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isDigit) else {
            return nil
          }
          guard let _ = self.parseString(
            from: &index,
            minCount: 3,
            maxCount: 3,
            while: \._isAlphanumeric
          ) else {
            return nil
          }
          if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
            return nil
          }
          return (Variant(ASCIICaseInsensitiveString(String(string[..<index]))), index)
        }
      }
    }

    public init?<S>(_ string: S) where S: StringProtocol {
      self.init(string, parser: Parser<S>.self)
    }
  } // Variant

  /// Represents `extension`
  public struct Extension: Sendable,
                           LosslessStringConvertible,
                           Equatable,
                           Hashable,
                           _InitializableWithParser {
    /// Singleton prefix of the extension.
    public struct Singleton: Sendable, Equatable, Hashable, Comparable {
      public let value: Unicode.UTF8.CodeUnit

      fileprivate init(_validatedValue value: Unicode.UTF8.CodeUnit) {
        assert(value._isSingleton)
        self.value = value
      }

      public init?(_ value: Unicode.UTF8.CodeUnit) {
        guard value._isSingleton else {
          return nil
        }
        self.init(_validatedValue: value)
      }

      public init?(_ unicodeScalar: Unicode.Scalar) {
        guard unicodeScalar.isASCII else {
          return nil
        }
        self.init(UInt8(unicodeScalar.value))
      }

      @inlinable
      public static func ==(lhs: Singleton, rhs: Singleton) -> Bool {
        if lhs.value == rhs.value {
          return true
        }
        if lhs.value >= 0x61 {
          return lhs.value - 0x20 == rhs.value
        }
        if rhs.value >= 0x61 {
          return lhs.value == rhs.value - 0x20
        }
        return false
      }

      public func hash(into hasher: inout Hasher) {
        if self.value < 0x61 {
          hasher.combine(self.value)
        } else {
          hasher.combine(self.value - 0x20)
        }
      }

      @inlinable
      public static func <(lhs: Singleton, rhs: Singleton) -> Bool {
        let lUpper = lhs.value >= 0x61 ? lhs.value - 0x20 : lhs.value
        let rUpper = rhs.value >= 0x61 ? rhs.value - 0x20 : rhs.value
        return lUpper < rUpper
      }
    } // Extension.Singleton

    /// A value of the extension.
    public struct Value: Sendable,
                         Equatable,
                         Hashable,
                         _InitializableWithParser,
                         LosslessStringConvertible {
      private let _string: ASCIICaseInsensitiveString

      public var description: String { _string.description }

      fileprivate init(_validatedString string: ASCIICaseInsensitiveString) {
        self._string = string
      }

      internal struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
        typealias Output = Value

        let string: Input
        let utf8: Input.UTF8View

        init(input: Input) {
          self.string = input
          self.utf8 = input.utf8
        }

        mutating func parse() -> (output: Value, endIndex: Input.Index)? {
          var index = utf8.startIndex
          guard let string = self.parseString(
            from: &index,
            minCount: 2,
            maxCount: 8,
            while: \._isAlphanumeric
          ) else {
            return nil
          }
          if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
            return nil
          }
          return (Value(_validatedString: string[..<index]._caseInsensitive), index)
        }
      }

      public init?(_ description: String) {
        self.init(description, parser: Parser<String>.self)
      }
    } // Extension.Value

    private let _wholeString: ASCIICaseInsensitiveString

    /// The first character of this subtag, which is called "singleton (prefix)".
    public let singleton: Singleton

    public let values: [Value]

    public var description: String { _wholeString._string }

    public static func ==(lhs: Extension, rhs: Extension) -> Bool {
      return lhs._wholeString == rhs._wholeString
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(_wholeString)
    }

    fileprivate init(
      _validatedString wholeString: ASCIICaseInsensitiveString,
      singleton: Singleton,
      values: [Value]
    ) {
      self._wholeString = wholeString
      self.singleton = singleton
      self.values = values
    }

    internal struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
      typealias Output = Extension

      let string: Input
      let utf8: Input.UTF8View

      init(input: Input) {
        self.string = input
        self.utf8 = input.utf8
      }

      mutating func parse() -> (output: Extension, endIndex: Input.Index)? {
        var index = utf8.startIndex

        guard let singletonByte = self.readCurrentCodeUnit(
          at: &index,
          ifAllowedCodeUnit: \._isSingleton
        ) else {
          return nil
        }

        let singleton = Singleton(_validatedValue: singletonByte)

        let valuesParser = RepetitionParser<
          Input.SubSequence,
          _HyphenFollowedBy<
            Value.Parser<Input.SubSequence.SubSequence.SubSequence>,
            Input.SubSequence.SubSequence
          >
        >(input: string[index...])

        guard let valuesResult = valuesParser.parse() else {
          return nil
        }

        return (
          Extension(
            _validatedString: string[..<valuesResult.endIndex]._caseInsensitive,
            singleton: singleton,
            values: valuesResult.output
          ),
          valuesResult.endIndex
        )
      }
    } // Extension.Parser

    public init?<S>(_ string: S) where S: StringProtocol {
      self.init(string, parser: Parser<S>.self)
    }

    /// A list of `Extension`s.
    public struct List: Sendable, Equatable, Hashable, Sequence {
      public typealias Element = Extension
      public typealias Iterator = Array<Extension>.Iterator

      private var _extensions: [Singleton: Extension]

      /// A Boolean value indicating whether the list is empty.
      public var isEmpty: Bool {
        return _extensions.isEmpty
      }

      public var extensions: [Extension] {
        return _extensions.sorted(by: { $0.key < $1.key }).map({ $0.value })
      }

      public func makeIterator() -> Array<Extension>.Iterator {
        return self.extensions.makeIterator()
      }

      @discardableResult
      public mutating func insert(_ newExtension: Extension) -> (replaced: Bool, oldExtension: Extension?) {
        let oldExtension = _extensions.updateValue(newExtension, forKey: newExtension.singleton)
        return (replaced: !oldExtension.isNil, oldExtension: oldExtension)
      }

      public init() {
        self._extensions = [:]
      }

      @inlinable
      public init<S>(_ extensions: S) where S: Sequence, S.Element == Extension {
        if case let list as Self = extensions {
          self = list
          return
        }
        self.init()
        extensions.forEach({ self.insert($0) })
      }
    }
  } // Extension

  public typealias ExtensionList = Extension.List

  /// Represents `privateuse`.
  public struct PrivateUseTag: Sendable,
                               LosslessStringConvertible,
                               Equatable,
                               Hashable,
                               _InitializableWithParser {
    private let _string: ASCIICaseInsensitiveString

    public var description: String { String(describing: _string) }

    fileprivate init(_ string: ASCIICaseInsensitiveString) {
      self._string = string
    }

    internal struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
      typealias Output = PrivateUseTag

      let string: Input
      let utf8: Input.UTF8View

      init(input: Input) {
        self.string = input
        self.utf8 = input.utf8
      }

      mutating func parse() -> (output: PrivateUseTag, endIndex: Input.Index)? {
        var index = utf8.startIndex

        guard let _ = self.readCurrentCodeUnit(
          at: &index,
          ifAllowedCodeUnit: { $0 == 0x58 || $0 == 0x78 } // "X" or "x"
        ) else {
          return nil
        }

        func __consumeNextTag() -> Input.Index? {
          let startIndex = index
          guard let _ = self.readCurrentCodeUnit(
            at: &index,
            ifAllowedCodeUnit: { $0 == 0x2D } // "-"
          ) else {
            return nil
          }
          guard let _ = self.parseString(
            from: &index,
            minCount: 1,
            maxCount: 8,
            while: \._isAlphanumeric
          ) else {
            index = startIndex
            return nil
          }
          if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAlphanumeric) {
            return nil
          }
          return index
        }

        guard let _ = __consumeNextTag() else { return nil }
        while let _ = __consumeNextTag() {}
        return (PrivateUseTag(ASCIICaseInsensitiveString(String(string[..<index]))), index)
      }
    } // PrivateUseTag.Parser

    public init?<S>(_ string: S) where S: StringProtocol {
      self.init(string, parser: Parser<S>.self)
    }
  } // PrivateUseTag

  /// Represents `grandfathered`.
  public struct GrandfatheredTag: Sendable, LosslessStringConvertible, Equatable, Hashable {
    private let _string: ASCIICaseInsensitiveString

    public var description: String { String(describing: _string) }

    private static let _irregulars: Set<ASCIICaseInsensitiveString> = [
      "en-GB-oed",
      "i-ami",
      "i-bnn",
      "i-default",
      "i-enochian",
      "i-hak",
      "i-klingon",
      "i-lux",
      "i-mingo",
      "i-navajo",
      "i-pwn",
      "i-tao",
      "i-tay",
      "i-tsu",
      "sgn-BE-FR",
      "sgn-BE-NL",
      "sgn-CH-DE",
    ]

    private static let _regulars: Set<ASCIICaseInsensitiveString> = [
      "art-lojban",
      "cel-gaulish",
      "no-bok",
      "no-nyn",
      "zh-guoyu",
      "zh-hakka",
      "zh-min",
      "zh-min-nan",
      "zh-xiang",
    ]

    fileprivate init(_validatedString string: ASCIICaseInsensitiveString) {
      self._string = string
    }

    public init?(_ string: String) {
      let caseInsensitiveString = ASCIICaseInsensitiveString(string)
      guard (
        GrandfatheredTag._irregulars.contains(caseInsensitiveString) ||
        GrandfatheredTag._regulars.contains(caseInsensitiveString)
      ) else {
        return nil
      }
      self.init(_validatedString: caseInsensitiveString)
    }

    fileprivate static let _reverseOrderedTags: [ASCIICaseInsensitiveString] = _irregulars.union(
      _regulars
    ).sorted(by: {
      $0._string > $1._string
    })

    internal struct Parser<Input>: StringParser where Input: StringProtocol {
      typealias Output = GrandfatheredTag

      let string: ASCIICaseInsensitiveString

      init(input: Input) {
        self.string = ASCIICaseInsensitiveString(String(input))
      }

      mutating func parse() -> (output: GrandfatheredTag, endIndex: Input.Index)? {
        for aTag in _reverseOrderedTags {
          if let endIndex = string._endIndex(ofPrefix: aTag._string) {
            let validated = ASCIICaseInsensitiveString(String(string[..<endIndex]))
            return (GrandfatheredTag(_validatedString: validated), endIndex)
          }
        }
        return nil
      }
    }
  } // GrandfatheredTag

  fileprivate enum _Tag: Equatable, Hashable {
    case languageTag(
      language: Language,
      script: Script?,
      region: Region?,
      variants: [Variant]?,
      extensions: ExtensionList?,
      privateUseTag: PrivateUseTag?
    )
    case privateUseTag(PrivateUseTag)
    case grandfatheredTag(GrandfatheredTag)

    mutating func emptyToNil() {
      guard case .languageTag(
        let language,
        let script,
        let region,
        let variants,
        let extensions,
        let privateUseTag
      ) = self else {
        return
      }
      if variants.isNil && extensions.isNil {
        return
      }
      self = .languageTag(
        language: language,
        script: script,
        region: region,
        variants: variants?.isEmpty == false ? variants : nil,
        extensions: extensions?.isEmpty == false ? extensions : nil,
        privateUseTag: privateUseTag
      )
    }
  }

  private let _string: ASCIICaseInsensitiveString?

  private let _tag: _Tag

  public static func ==(lhs: LanguageTagString, rhs: LanguageTagString) -> Bool {
    guard let lString = lhs._string, let rString = rhs._string else {
      return lhs._tag == rhs._tag
    }
    return lString == rString
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(_tag)
  }

  public var language: Language? {
    guard case .languageTag(let language, _, _, _, _, _) = _tag else {
      return nil
    }
    return language
  }

  public var script: Script? {
    guard case .languageTag(_, let script?, _, _, _, _) = _tag else {
      return nil
    }
    return script
  }


  public var region: Region? {
    guard case .languageTag(_, _, let region?, _, _, _) = _tag else {
      return nil
    }
    return region
  }

  public var variants: [Variant]? {
    guard case .languageTag(_, _, _, let variants?, _, _) = _tag, !variants.isEmpty else {
      return nil
    }
    return variants
  }

  public var extensions: ExtensionList? {
    guard case .languageTag(_, _, _, _, let extensions?, _) = _tag, !extensions.isEmpty else {
      return nil
    }
    return extensions
  }

  public var privateUseTag: PrivateUseTag? {
    guard case .languageTag(_, _, _, _, _, let privateUseTag?) = _tag else {
      return nil
    }
    return privateUseTag
  }

  public var isPrivateUseTag: Bool {
    if case .privateUseTag = _tag {
      return true
    }
    return false
  }

  public var isGrandfatheredTag: Bool {
    if case .grandfatheredTag = _tag {
      return true
    }
    return false
  }

  public var description: String {
    if let string = self._string {
      return string._string
    }

    switch self._tag {
    case .languageTag(
      let language,
      let optScript,
      let optRegion,
      let optVariants,
      let optExtensions,
      let optPrivateUseTag
    ):
      var description = language.description

      func __appendDescription<T>(of optSomething: T?) where T: CustomStringConvertible {
        guard let something = optSomething else {
          return
        }
        description += "-\(something.description)"
      }

      __appendDescription(of: optScript)
      __appendDescription(of: optRegion)
      optVariants.map({ $0.forEach(__appendDescription(of:)) })
      optExtensions.map({ $0.forEach(__appendDescription(of:)) })
      __appendDescription(of: optPrivateUseTag)
      return description
    case .privateUseTag(let privateUseTag):
      return privateUseTag.description
    case .grandfatheredTag(let grandfatheredTag):
      return grandfatheredTag.description
    }
  }

  fileprivate init(
    _validatedString string: ASCIICaseInsensitiveString?,
    parsedTag: _Tag
  ) {
    var tag = parsedTag
    tag.emptyToNil()

    self._string = string
    self._tag = tag
  }

  public init<Variants, Extensions>(
    language: Language,
    script: Script? = nil,
    region: Region? = nil,
    variants: Variants? = Optional<Array<Variant>>.none,
    extensions: Extensions? = Optional<ExtensionList>.none,
    privateUseTag: PrivateUseTag? = nil
  )
  where Variants: Sequence, Variants.Element == Variant,
  Extensions: Sequence, Extensions.Element == Extension {
    self.init(
      _validatedString: nil,
      parsedTag: .languageTag(
        language: language,
        script: script,
        region: region,
        variants: variants.map({ Array<Variant>($0) }),
        extensions: extensions.map({ ExtensionList($0) }),
        privateUseTag: privateUseTag
      )
    )
  }

  public init(privateUseTag: PrivateUseTag) {
    self.init(_validatedString: nil, parsedTag: .privateUseTag(privateUseTag))
  }

  public init(grandfatheredTag: GrandfatheredTag) {
    self.init(_validatedString: nil, parsedTag: .grandfatheredTag(grandfatheredTag))
  }
}

/// A parser that generates `LanguageTagString`
public struct LanguageTagStringParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = LanguageTagString

  public let string: Input

  public init(input: Input) {
    self.string = input
  }

  public mutating func parse() -> (output: LanguageTagString, endIndex: Input.Index)? {
    if let languageResult = LanguageTagString.Language.Parser<Input>.parse(string) {
      let language = languageResult.output
      var index = languageResult.endIndex

      func __parseAndAdvance<T>(with parserType: T.Type) -> T.Output?
      where T: StringParser, T.Input == Input.SubSequence {
        guard let result = T.parse(string[index...]) else {
          return nil
        }
        index = result.endIndex
        return result.output
      }

      let script = __parseAndAdvance(
        with: _HyphenFollowedBy<
          LanguageTagString.Script.Parser<Input.SubSequence.SubSequence>,
          Input.SubSequence
        >.self
      )

      let region = __parseAndAdvance(
        with: _HyphenFollowedBy<
          LanguageTagString.Region.Parser<Input.SubSequence.SubSequence>,
          Input.SubSequence
        >.self
      )

      let variants = __parseAndAdvance(
        with: RepetitionParser<
          Input.SubSequence,
          _HyphenFollowedBy<
            LanguageTagString.Variant.Parser<Input.SubSequence.SubSequence.SubSequence>,
            Input.SubSequence.SubSequence
          >
        >.self
      )

      var extensionsAreCanonicallyOrdered = true
      var extensionList = LanguageTagString.Extension.List()
      typealias _NextExtensionParser = _HyphenFollowedBy<
        LanguageTagString.Extension.Parser<Input.SubSequence.SubSequence>,
        Input.SubSequence
      >
      if let firstExtension = __parseAndAdvance(with: _NextExtensionParser.self) {
        extensionList.insert(firstExtension)
        var lastMaxSingleton = firstExtension.singleton
        while let anExtension = __parseAndAdvance(with: _NextExtensionParser.self) {
          if extensionList.insert(anExtension).replaced { // No duplication allowed
            return nil
          }
          assert(lastMaxSingleton != anExtension.singleton)
          if lastMaxSingleton > anExtension.singleton {
            extensionsAreCanonicallyOrdered = false
          } else {
            lastMaxSingleton = anExtension.singleton
          }
        }
      }

      let privateUseTag = __parseAndAdvance(
        with: _HyphenFollowedBy<
          LanguageTagString.PrivateUseTag.Parser<Input.SubSequence.SubSequence>,
          Input.SubSequence
        >.self
      )

      return (
        LanguageTagString(
          _validatedString: (
            extensionsAreCanonicallyOrdered ? string[..<index]._caseInsensitive : nil
          ),
          parsedTag: .languageTag(
            language: language,
            script: script,
            region: region,
            variants: variants,
            extensions: extensionList,
            privateUseTag: privateUseTag
          )
        ),
        index
      )
    } else if let privateUseTagResult = LanguageTagString.PrivateUseTag.Parser<Input>.parse(string) {
      return (
        LanguageTagString(
          _validatedString: string[..<privateUseTagResult.endIndex]._caseInsensitive,
          parsedTag: .privateUseTag(privateUseTagResult.output)
        ),
        privateUseTagResult.endIndex
      )
    } else if let grandfatheredTagResult = LanguageTagString.GrandfatheredTag.Parser<Input>.parse(string) {
      return (
        LanguageTagString(
          _validatedString: string[..<grandfatheredTagResult.endIndex]._caseInsensitive,
          parsedTag: .grandfatheredTag(grandfatheredTagResult.output)
        ),
        grandfatheredTagResult.endIndex
      )
    }
    return nil
  }
}

extension LanguageTagString: _InitializableWithParser, LosslessStringConvertible {
  public init?<S>(_ description: S) where S: StringProtocol {
    self.init(description, parser: LanguageTagStringParser<_>.self)
  }
}

extension LanguageTagString {
  /// Create a `Locale` instance from the string.
  @inlinable
  public var locale: Locale { return Locale(identifier: self.description) }

  /// Create an instance from `locale`.
  public init?(_ locale: Locale) {
    self.init(locale.identifier(.bcp47))
  }
}
