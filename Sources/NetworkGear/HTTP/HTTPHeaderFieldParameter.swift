/* *************************************************************************************************
 HTTPHeaderFieldParameter.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import Ranges
import yExtensions

/// Key-value pairs for "HTTP Parameter Continuations".
///
/// - NOTE:
///     String validation may be done loosely for compatibility.
///
/// - References:
///     - [RFC 2231](https://datatracker.ietf.org/doc/html/rfc2231)
///     - [RFC 8187 §3.1](https://datatracker.ietf.org/doc/html/rfc8187#section-3.1)
public struct HTTPHeaderFieldParameter: Sendable {
  /// A regular parameter name.
  public struct Name: Sendable, Equatable, CustomStringConvertible {
    public let attribute: ASCIICaseInsensitiveString

    public let sectionIndex: Int?

    public var description: String {
      guard let sectionIndex = self.sectionIndex else {
        return attribute.description
      }
      return "\(attribute.description)*\(String(sectionIndex, radix: 10))"
    }

    fileprivate init(
      _validatedAttribute attribute: ASCIICaseInsensitiveString,
      sectionIndex: Int?
    ) {
      self.attribute = attribute
      self.sectionIndex = sectionIndex
    }

    /// Creates an instance with `utf8`, which must be already validated.
    internal init<C>(_analyzing utf8: C)
    where C: BidirectionalCollection, C.Element == Unicode.UTF8.CodeUnit {
      assert(!utf8.isEmpty)
      let lastU8Index = utf8.index(before: utf8.endIndex)

      // NOTE:
      //   While any specification doesn't define max number of section index,
      //   we should set a maximum value for some security reasons.

      var index = lastU8Index
      var count = 0
      var sectionIndex: Int? = nil
      while index >= utf8.startIndex {
        count += 1
        if count > 4 {
          break
        }
        let u8 = utf8[index]
        if !u8._isDigit {
          if u8._isAsterisk && count > 1 {
            sectionIndex = utf8[index<..].reduce(into: 0 as Int) { $0 = $0 * 10 + Int($1 - 0x30)  }
          }
          break
        }
        utf8.formIndex(before: &index)
      }

      guard let validSectionIndex = sectionIndex else {
        self.init(
          _validatedAttribute: String(decoding: utf8, as: Unicode.UTF8.self)._caseInsensitive,
          sectionIndex: nil
        )
        return
      }
      let attribute = String(decoding: utf8[..<index], as: Unicode.UTF8.self)._caseInsensitive
      self.init(_validatedAttribute: attribute, sectionIndex: validSectionIndex)
    }
  }

  /// An extended name.
  public struct ExtendedName: Sendable, Equatable, CustomStringConvertible {
    public let baseName: Name

    @inlinable
    public var attribute: ASCIICaseInsensitiveString { baseName.attribute }

    @inlinable
    public var sectionIndex: Int? { baseName.sectionIndex }

    public var description: String { baseName.description + "*" }

    fileprivate init(_baseName baseName: Name) {
      self.baseName = baseName
    }
  }

  /// A regular value.
  public struct Value: Sendable, Equatable, LosslessStringConvertible {
    private enum _Value: Sendable, Equatable {
      case token(HTTPTokenString)
      case quotedString(QuotedString)

      static func ==(lhs: _Value, rhs: _Value) -> Bool {
        switch (lhs, rhs) {
        case (.token(let lToken), .token(let rToken)): return lToken == rToken
        case (.quotedString(let lQS), .quotedString(let rQS)): return lQS.content == rQS.content
        default: return false
        }
      }
    }

    private let _value: _Value

    public var description: String {
      switch self._value {
      case .token(let token): return token.description
      case .quotedString(let quotedString): return quotedString.quotedString
      }
    }

    private init(_value value: _Value) {
      self._value = value
    }

    public init(token: HTTPTokenString) {
      self.init(_value: .token(token))
    }

    public init(quotedString: QuotedString) {
      self.init(_value: .quotedString(quotedString))
    }

    @inlinable
    public init?<S>(_ description: S) where S: StringProtocol {
      if let token = HTTPTokenString(validating: description) {
        self.init(token: token)
      } else if let quotedString = QuotedString(validating: description) {
        self.init(quotedString: quotedString)
      } else {
        return nil
      }
    }
  }

  public struct ExtendedValue: Sendable, Equatable, CustomStringConvertible {
    /// String representation of "MIME Charset".
    public let stringEncodingDescription: String

    /// String representation of "Language Tag"
    public let languageTagDescription: LanguageTagString?

    /// Percent-encoded value.
    public let percentEncodedValue: PercentEncodedString

    public var description: String {
      return "\(stringEncodingDescription)'\(languageTagDescription?.description ?? "")'\(percentEncodedValue.encodedString)"
    }

    public var stringEncoding: String.Encoding? {
      #if compiler(>=6.3)
      if #available(macOS 26.4, iOS 26.4, *),
         let encoding = String.Encoding(ianaName: stringEncodingDescription) {
        return encoding
      }
      #endif
      return String.Encoding(ianaCharacterSetName: stringEncodingDescription)
    }

    public var locale: Locale? {
      return languageTagDescription?.locale
    }

    public var decodedValue: String? {
      if let stringEncoding = self.stringEncoding {
        return percentEncodedValue.decodedString(usingStringEncoding: stringEncoding)
      } else {
        return percentEncodedValue.decodedString
      }
    }

    @inlinable
    internal init(_validated: (
        stringEncodingDescription: String,
        languageTagDescription: LanguageTagString?,
        percentEncodedValue: PercentEncodedString
    )) {
      self.stringEncodingDescription = _validated.stringEncodingDescription
      self.languageTagDescription = _validated.languageTagDescription
      self.percentEncodedValue = _validated.percentEncodedValue
    }
  }
}

internal enum _ParameterName: Sendable {
  case regular(HTTPHeaderFieldParameter.Name)
  case extended(HTTPHeaderFieldParameter.ExtendedName)

  @inlinable
  var isReqular: Bool {
    if case .regular = self {
      true
    } else {
      false
    }
  }

  @inlinable
  var isExtended: Bool {
    if case .extended = self {
      true
    } else {
      false
    }
  }

  @inlinable
  var attribute: ASCIICaseInsensitiveString {
    switch self {
    case .regular(let name):
      return name.attribute
    case .extended(let extendedName):
      return extendedName.attribute
    }
  }

  @inlinable
  var sectionIndex: Int? {
    switch self {
    case .regular(let name):
      return name.sectionIndex
    case .extended(let extendedName):
      return extendedName.sectionIndex
    }
  }
}

internal struct _MIMECompatibleParameterNameParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  typealias Output = _ParameterName
  typealias RegularName = HTTPHeaderFieldParameter.Name
  typealias ExtendedName = HTTPHeaderFieldParameter.ExtendedName

  let string: Input
  let utf8: Input.UTF8View

  init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  mutating func parse() -> (output: _ParameterName, endIndex: Input.Index)? {
    var index = utf8.startIndex

    guard let attributeString = self.parseString(
      from: &index,
      while: \._isAvailableInParameterNameForMIME
    ) else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAsterisk) else {
      let name = RegularName(
        _validatedAttribute: attributeString._caseInsensitive,
        sectionIndex: nil
      )
      return (.regular(name), index)
    }

    var numberOfDigits = 0
    guard let numberString = self.parseString(
      from: &index,
      count: &numberOfDigits,
      while: \._isDigit
    ) else {
      let baseName = RegularName(
        _validatedAttribute: attributeString._caseInsensitive,
        sectionIndex: nil
      )
      return (.extended(ExtendedName(_baseName: baseName)), index)
    }
    // Deny large section index
    if numberOfDigits > 4 {
      return nil
    }

    let baseName = RegularName(
      _validatedAttribute: attributeString._caseInsensitive,
      sectionIndex: Int(numberString)
    )
    if let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isAsterisk) {
      return (.extended(ExtendedName(_baseName: baseName)), index)
    }
    return (.regular(baseName), index)
  }
}

internal struct _HTTPHeaderFieldParameterNameParser<Input>: StringParser
where Input: StringProtocol {
  typealias Output = _ParameterName
  typealias RegularName = HTTPHeaderFieldParameter.Name
  typealias ExtendedName = HTTPHeaderFieldParameter.ExtendedName

  private let _string: Input
  init(input: Input) {
    self._string = input
  }

  mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    guard let (token, endIndex) = HTTPTokenParser<Input>.parse(_string) else {
      return nil
    }

    let tokenUTF8 = token.utf8
    EXTENDED_NAME: if tokenUTF8.last!._isAsterisk {
      let baseNameToken = tokenUTF8.dropLast()
      if baseNameToken.isEmpty {
        break EXTENDED_NAME
      }
      let baseName = RegularName(_analyzing: baseNameToken)
      return (.extended(ExtendedName(_baseName: baseName)), endIndex)
    }
    return (.regular(RegularName(_analyzing: tokenUTF8)), endIndex)
  }
}

public struct ExtendedParameterValueParser<Input>: StringParser,
                                                   _UTF8Parser where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameter.ExtendedValue

  let string: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: HTTPHeaderFieldParameter.ExtendedValue, endIndex: Input.Index)? {
    var index = utf8.startIndex
    guard let stringEncodingDescription = self.parseString(
      from: &index,
      while: \._isAvailableInMIMECharsetInExtendedValue
    ) else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isApostrophe) else {
      return nil
    }

    var languageTagDescription: LanguageTagString? = nil
    if let langTagResult = LanguageTagStringParser<Input.SubSequence>.parse(string[index...]) {
      languageTagDescription = langTagResult.output
      index = langTagResult.endIndex
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isApostrophe) else {
      return nil
    }

    guard let percentEncodedString = self.parseString(
      from: &index,
      while: \._isAvailableInPercentEncodedContentInExtendedValue
    ) else {
      return nil
    }
    let percentEncodedValue = PercentEncodedString(encodedString: percentEncodedString._string)

    return (
      output: HTTPHeaderFieldParameter.ExtendedValue(_validated: (
        stringEncodingDescription: stringEncodingDescription._string,
        languageTagDescription: languageTagDescription,
        percentEncodedValue: percentEncodedValue
      )),
      endIndex: index
    )
  }
}

extension HTTPHeaderFieldParameter.ExtendedValue: _InitializableWithParser, LosslessStringConvertible {
  /// Creates an instance from `string`.
  public init?<S>(_ description: S) where S: StringProtocol {
    self.init(description, parser: ExtendedParameterValueParser<S>.self)
  }
}
