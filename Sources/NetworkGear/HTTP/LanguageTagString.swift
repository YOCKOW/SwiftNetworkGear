/* *************************************************************************************************
 LanguageTagString.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import yExtensions

private extension Unicode.UTF8.CodeUnit {
  var _isSingleton: Bool {
    if _isDigit {
      return true
    }
    if 0x41 <= self && self <= 0x57 { // A-W
      return true
    }
    if 0x59 <= self && self <= 0x5A { // Y-Z
      return true
    }
    if 0x61 <= self && self <= 0x77 { // a-w
      return true
    }
    if 0x79 <= self && self <= 0x7A { // y-z
      return true
    }
    return false
  }
}

/// A string that represents ["Language Tag"](https://datatracker.ietf.org/doc/html/rfc5646).
public struct LanguageTagString: Sendable {
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
    private let _string: ASCIICaseInsensitiveString

    public var description: String { String(describing: _string) }

    fileprivate init(_ string: ASCIICaseInsensitiveString) {
      self._string = string
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

        guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isSingleton) else {
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
            minCount: 2,
            maxCount: 8,
            while: \._isAlphanumeric
          ) else {
            index = startIndex
            return nil
          }
          return index
        }

        guard let _ = __consumeNextTag() else { return nil }
        while let _ = __consumeNextTag() {}
        return (Extension(ASCIICaseInsensitiveString(String(string[..<index]))), index)
      }
    } // Extension.Parser

    public init?<S>(_ string: S) where S: StringProtocol {
      self.init(string, parser: Parser<S>.self)
    }
  } // Extension

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

    public init?(_ string: String) {
      let caseInsensitiveString = ASCIICaseInsensitiveString(string)
      guard (
        GrandfatheredTag._irregulars.contains(caseInsensitiveString) ||
        GrandfatheredTag._regulars.contains(caseInsensitiveString)
      ) else {
        return nil
      }
      self._string = caseInsensitiveString
    }
  } // GrandfatheredTag
}
