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
/// This type is designed to be compatible with "MIME Parameter Value and Encoded Word Extensions".
///
/// - NOTE:
///     String validation may be done loosely for compatibility.
///
/// - References:
///     - [RFC 2231](https://datatracker.ietf.org/doc/html/rfc2231)
///     - [RFC 8187 §3.1](https://datatracker.ietf.org/doc/html/rfc8187#section-3.1)
///
/// - Examples of parameter:
///     + `foo=bar`
///     + `foo="bar"`
///     + `foo*=UTF-8''percent-encoded-bar`
public struct HTTPHeaderFieldParameter: Sendable, Equatable, Hashable {
  /// A regular parameter name.
  public struct Name: Sendable, Equatable, Hashable, CustomStringConvertible {
    public let attribute: ASCIICaseInsensitiveString

    public let sectionIndex: Int?

    public func hash(into hasher: inout Hasher) {
      hasher.combine(attribute)
      hasher.combine(sectionIndex)
    }

    public var description: String {
      guard let sectionIndex = self.sectionIndex else {
        return attribute.description
      }
      return "\(attribute.description)*\(String(sectionIndex, radix: 10))"
    }

    @inlinable
    internal init(
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
  public struct ExtendedName: Sendable, Equatable, Hashable, CustomStringConvertible {
    public let baseName: Name

    @inlinable
    public var attribute: ASCIICaseInsensitiveString { baseName.attribute }

    @inlinable
    public var sectionIndex: Int? { baseName.sectionIndex }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(baseName)
      hasher.combine(1)
    }

    public var description: String { baseName.description + "*" }

    @usableFromInline
    internal init(_baseName baseName: Name) {
      self.baseName = baseName
    }
  }

  /// A regular value.
  public struct Value: Sendable, Equatable, Hashable, CustomStringConvertible {
    fileprivate enum _Value: Sendable, Equatable, Hashable {
      case token(any HTTPTokenStringProtocol)
      case quotedString(QuotedString)

      static func ==(lhs: _Value, rhs: _Value) -> Bool {
        switch (lhs, rhs) {
        case (.token(let lToken), .token(let rToken)): return lToken._isEqual(to: rToken)
        case (.quotedString(let lQS), .quotedString(let rQS)): return lQS.content == rQS.content
        default: return false
        }
      }

      func hash(into hasher: inout Hasher) {
        switch self {
        case .token(let token):
          hasher.combine(token)
        case .quotedString(let quotedString):
          hasher.combine(quotedString.content)
        }
      }
    }

    fileprivate let _value: _Value

    public var description: String {
      switch self._value {
      case .token(let token): return token.description
      case .quotedString(let quotedString): return quotedString.quotedString
      }
    }

    /// A string of the value.
    public var content: String {
      switch self._value {
      case .token(let token): return token._string._string
      case .quotedString(let quotedString): return quotedString.content
      }
    }

    private init(_value value: _Value) {
      self._value = value
    }

    @usableFromInline
    internal init<T>(_token token: T) where T: HTTPTokenStringProtocol {
      self.init(_value: .token(token))
    }

    @inlinable
    public init(token: HTTPTokenString) {
      self.init(_token: token)
    }

    @inlinable
    public init(token: HTTPTokenSubstring) {
      self.init(_token: token)
    }

    public init(quotedString: QuotedString) {
      self.init(_value: .quotedString(quotedString))
    }

    /// Create a new value by adding leading/trailing double quotation marks to the given `value`.
    ///
    /// - Returns: `nil` if `value` contains any byte which cannot be used in quoted string.
    public init?<S>(quoting value: S) where S: StringProtocol {
      guard let quoted = value._quotedString else {
        return  nil
      }
      self.init(quotedString: QuotedString(quotedString: quoted))
    }

    public func appending(_ other: Value) -> Value {
      switch (self._value, other._value) {
      case (.token(let myToken), .token(let otherToken)):
        return Value(token: myToken._appending(otherToken))
      case (.token(let myToken), .quotedString(let otherQuotedString)):
        return Value(quotedString: QuotedString(_token: myToken).appending(otherQuotedString))
      case (.quotedString(let myQuotedString), .token(let otherToken)):
        return Value(quotedString: myQuotedString.appending(_token: otherToken))
      case (.quotedString(let myQuotedString), .quotedString(let otherQuotedString)):
        return Value(quotedString: myQuotedString.appending(otherQuotedString))
      }
    }

    public mutating func append(_ other: Value) {
      self = self.appending(other)
    }
  }

  /// A type for an extended value.
  ///
  /// - Note: Conforming types are only `ExtendedValue` and `InformationlessExtendedValue`.
  public protocol ExtendedValueProtocol: Sendable, Equatable, Hashable, CustomStringConvertible {
    var percentEncodedValue: PercentEncodedString { get }
    var decodedValueData: Data { get }
    var decodedValue: String? { get }
    var isInformationless: Bool { get }
  }

  public struct ExtendedValue: ExtendedValueProtocol {
    /// String representation of "MIME Charset".
    public let stringEncodingDescription: ASCIICaseInsensitiveString

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
         let encoding = String.Encoding(ianaName: stringEncodingDescription._string) {
        return encoding
      }
      #endif
      return String.Encoding(ianaCharacterSetName: stringEncodingDescription._string)
    }

    public var locale: Locale? {
      return languageTagDescription?.locale
    }

    @inlinable
    public var decodedValueData: Data {
      return self.percentEncodedValue.decodedData
    }

    public var decodedValue: String? {
      if let stringEncoding = self.stringEncoding {
        return percentEncodedValue.decodedString(usingStringEncoding: stringEncoding)
      } else {
        return percentEncodedValue.decodedString
      }
    }

    public var isInformationless: Bool { false }

    @inlinable
    internal init(_validated: (
        stringEncodingDescription: ASCIICaseInsensitiveString,
        languageTagDescription: LanguageTagString?,
        percentEncodedValue: PercentEncodedString
    )) {
      self.stringEncodingDescription = _validated.stringEncodingDescription
      self.languageTagDescription = _validated.languageTagDescription
      self.percentEncodedValue = _validated.percentEncodedValue
    }

    public init?<S>(
      addingPercentEncodingToValue value: S,
      usingStringEncoding stringEncoding: String.Encoding,
      locale: Locale? = nil
    ) where S: StringProtocol {
      guard let stringEncodingDescription = stringEncoding.ianaCharacterSetName else {
        return nil
      }
      let languageTagDescription = locale.flatMap({ LanguageTagString($0.identifier(.bcp47)) })
      guard let percentEncodedValue = value.addingPercentEncoding(
        usingStringEncoding: stringEncoding,
        whereAllowedASCIICharacters: { $0._isAvailableInHTTPHeaderFieldValue && !$0._isHTTPWhitespace }
      ).map({ PercentEncodedString(encodedString: $0) }) else {
        return nil
      }
      self.init(
        _validated: (
          stringEncodingDescription._caseInsensitive,
          languageTagDescription,
          percentEncodedValue
        )
      )
    }

    /// Create a new "extended value" by adding percent encoding to the given `value`.
    public init<S>(addingPercentEncodingToValue value: S) where S: StringProtocol {
      self.init(addingPercentEncodingToValue: value, usingStringEncoding: .utf8)!
    }
  }

  /// An extended value that contains only a percent-encoded string.
  /// This value is supposed to exist at the second or subsequent one in MIME header.
  public struct InformationlessExtendedValue: ExtendedValueProtocol {
    /// Percent-encoded value.
    public let percentEncodedValue: PercentEncodedString

    public var description: String { percentEncodedValue.encodedString }

    public var decodedValueData: Data {
      return percentEncodedValue.decodedData
    }

    public func decodedValue(usingStringEncoding stringEncoding: String.Encoding) -> String? {
      return percentEncodedValue.decodedString(usingStringEncoding: stringEncoding)
    }

    public var decodedValue: String? {
      return self.decodedValue(usingStringEncoding: .utf8)
    }

    public var isInformationless: Bool { true }

    @inlinable
    internal init(percentEncodedValue: PercentEncodedString) {
      self.percentEncodedValue = percentEncodedValue
    }
  }

  private enum _NameValuePair: Sendable, Equatable, Hashable {
    case regular(name: Name, value: Value)
    case extended(name: ExtendedName, value: ExtendedValue)
    case nonInitialExtended(name: ExtendedName, value: InformationlessExtendedValue)
  }

  private let _nameValuePair: _NameValuePair

  /// A Boolean value indicating whether or not the value is an "extended value".
  public var isExtended: Bool {
    switch _nameValuePair {
    case .extended, .nonInitialExtended:
      return true
    default:
      return false
    }
  }

  /// A string that is a core part of the name.
  public var attribute: ASCIICaseInsensitiveString {
    switch _nameValuePair {
    case .regular(let name, _):
      return name.attribute
    case .extended(let name, _):
      return name.attribute
    case .nonInitialExtended(name: let name, value: _):
      return name.attribute
    }
  }

  /// An index of the section. `nil` is returned if the value is not sectioned.
  public var sectionIndex: Int? {
    switch _nameValuePair {
    case .regular(let name, _):
      return name.sectionIndex
    case .extended(let name, _):
      return name.sectionIndex
    case .nonInitialExtended(name: let name, value: _):
      return name.sectionIndex
    }
  }

  public var nameDescription: String {
    switch _nameValuePair {
    case .regular(let name, _):
      return name.description
    case .extended(let name, _):
      return name.description
    case .nonInitialExtended(name: let name, value: _):
      return name.description
    }
  }

  /// A regular value.
  /// `nil` is returned if the value is "extended" one.
  public var regularValue: Value? {
    guard case .regular(_, let value) = _nameValuePair else {
      return nil
    }
    return value
  }

  /// An extended value if available.
  public var extendedValue: ExtendedValue? {
    guard case .extended(_, let value) = _nameValuePair else {
      return nil
    }
    return value
  }

  /// A non-initial extended value if available.
  public var informationlessExtendedValue: InformationlessExtendedValue? {
    guard case .nonInitialExtended(_, let value) = _nameValuePair else {
      return nil
    }
    return value
  }

  /// A string of the value.
  /// `nil` is returned only if the value is percent-encoded and decoding fails.
  ///
  /// - Note: If the value is `InformationlessExtendedValue`, UTF-8 is used to decode the value.
  public var value: String? {
    switch _nameValuePair {
    case .regular(_, let value):
      switch value._value {
      case .token(let token):
        return token._string._string
      case .quotedString(let quotedString):
        return quotedString.content
      }
    case .extended(_, let value):
      return value.decodedValue
    case .nonInitialExtended(_, let value):
      return value.decodedValue(usingStringEncoding: .utf8)
    }
  }

  public var valueDescription: String {
    switch _nameValuePair {
    case .regular(_, let value):
      return value.description
    case .extended(_, let value):
      return value.description
    case .nonInitialExtended(_, let value):
      return value.description
    }
  }

  /// Creates a parameter pair of the regular name and the regular value.
  public init(name: Name, value: Value) {
    self._nameValuePair = .regular(name: name, value: value)
  }

  /// Creates a parameter pair of the extended name and the extended value.
  public init(name: ExtendedName, value: ExtendedValue) {
    self._nameValuePair = .extended(name: name, value: value)
  }

  /// Creates a parameter pair of the extended name and the extended value.
  public init(name: ExtendedName, value: InformationlessExtendedValue) {
    self._nameValuePair = .nonInitialExtended(name: name, value: value)
  }

  /// Returns a regular parameter.
  public static func regular(name: Name, value: Value) -> HTTPHeaderFieldParameter {
    return .init(name: name, value: value)
  }

  /// Returns an extended parameter.
  public static func extended(name: ExtendedName, value: ExtendedValue) -> HTTPHeaderFieldParameter {
    return .init(name: name, value: value)
  }

  /// Returns an extended parameter.
  public static func extended(name: ExtendedName, value: InformationlessExtendedValue) -> HTTPHeaderFieldParameter {
    return .init(name: name, value: value)
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

  let input: Input
  let utf8: Input.UTF8View

  init(input: Input) {
    self.input = input
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
        _validatedAttribute: attributeString._string._caseInsensitive,
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
        _validatedAttribute: attributeString._string._caseInsensitive,
        sectionIndex: nil
      )
      return (.extended(ExtendedName(_baseName: baseName)), index)
    }
    // Deny large section index
    if numberOfDigits > 4 {
      return nil
    }

    let baseName = RegularName(
      _validatedAttribute: attributeString._string._caseInsensitive,
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

public struct HTTPHeaderFieldParameterValueParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameter.Value

  private let _string: Input

  public init(input: Input) {
    self._string = input
  }

  public mutating func parse() -> (output: HTTPHeaderFieldParameter.Value, endIndex: Input.Index)? {
    if let (token, endIndex) = HTTPTokenParser<Input>.parse(_string) {
      return (HTTPHeaderFieldParameter.Value(token: token), endIndex)
    } else if let (quotedString, endIndex) = QuotedStringParser<Input>.parse(_string) {
      return (HTTPHeaderFieldParameter.Value(quotedString: quotedString), endIndex)
    } else {
      return nil
    }
  }
}

extension HTTPHeaderFieldParameter.Value: _InitializableWithParser, LosslessStringConvertible {
  @inlinable
  public init?<S>(_ description: S) where S: StringProtocol {
    self.init(description, parser: HTTPHeaderFieldParameterValueParser<S>.self)
  }
}

public struct ExtendedParameterValueParser<Input>: StringParser,
                                                   _UTF8Parser where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameter.ExtendedValue

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
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
    if let langTagResult = LanguageTagStringParser<Input.SubSequence>.parse(input[index...]) {
      languageTagDescription = langTagResult.output
      index = langTagResult.endIndex
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isApostrophe) else {
      return nil
    }

    guard let percentEncodedValue = PercentEncodedStringParser<Input.SubSequence>.parse(
      input,
      from: &index,
      configuration: .init(
        allowedNonEncodedUTF8CodeUnits: \._isAvailableInExtendedValueWithoutPercentEncoding
      )
    ) else {
      return nil
    }
    
    return (
      output: HTTPHeaderFieldParameter.ExtendedValue(_validated: (
        stringEncodingDescription: stringEncodingDescription._string._caseInsensitive,
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

public struct InformationlessExtendedParameterValueParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameter.InformationlessExtendedValue

  let input: Input

  public init(input: Input) {
    self.input = input
  }

  public mutating func parse() -> (
    output: HTTPHeaderFieldParameter.InformationlessExtendedValue,
    endIndex: Input.Index
  )? {
    var parser = PercentEncodedStringParser<Input>(
      input: input,
      allowedNonEncodedUTF8CodeUnits: \._isAvailableInExtendedValueWithoutPercentEncoding
    )
    guard let result = parser.parse() else {
      return nil
    }
    return (.init(percentEncodedValue: result.output), result.endIndex)
  }
}

extension HTTPHeaderFieldParameter.InformationlessExtendedValue: _InitializableWithParser, LosslessStringConvertible {
  public init?<S>(_ description: S) where S: StringProtocol {
    self.init(description, parser: InformationlessExtendedParameterValueParser<S>.self)
  }
}


/// A parser for `HTTPHeaderFieldParameter`.
public struct HTTPHeaderFieldParameterParser<Input>: @unchecked Sendable, StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameter

  public struct Configuration {
    public enum Mode {
      case `default`
      case mimeCompatible
    }

    public var mode: Mode

    public init(mode: Mode) {
      self.mode = mode
    }
  }

  let input: Input
  let utf8: Input.UTF8View
  public let configuration: Configuration?

  public var mode: Configuration.Mode {
    return self.configuration?.mode ?? .default
  }

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  public init(input: Input, mode: Configuration.Mode) {
    self.init(input: input, configuration: Configuration(mode: mode))
  }

  public func parse() -> (output: HTTPHeaderFieldParameter, endIndex: Input.Index)? {
    var nameParser: any StringParser<Input, _ParameterName> = switch self.mode {
    case .default: _HTTPHeaderFieldParameterNameParser<Input>(input: self.input)
    case .mimeCompatible: _MIMECompatibleParameterNameParser(input: self.input)
    }

    guard let (name, nameEndIndex) = nameParser.parse() else {
      return nil
    }

    var index = nameEndIndex
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isEqualSign) else {
      return nil
    }

    let valueInput = self.input[index...]
    switch name {
    case .regular(let name):
      guard let (value, endIndex) = HTTPHeaderFieldParameterValueParser<Input.SubSequence>.parse(
        valueInput
      ) else {
        return nil
      }
      return (
        output: HTTPHeaderFieldParameter(name: name, value: value),
        endIndex: endIndex
      )
    case .extended(let extendedName):
      if let (extendedValue, endIndex) = ExtendedParameterValueParser<Input.SubSequence>.parse(
        valueInput
      ) {
        return (
          output: HTTPHeaderFieldParameter(name: extendedName, value: extendedValue),
          endIndex: endIndex
        )
      }
      if let (otherValue, endIndex) = InformationlessExtendedParameterValueParser<Input.SubSequence>.parse(
        valueInput
      ) {
        return (
          output: HTTPHeaderFieldParameter(name: extendedName, value: otherValue),
          endIndex: endIndex
        )
      }
      return nil
    }
  }
}

extension HTTPHeaderFieldParameter.Name {
  @inlinable
  public init?<S>(
    attribute: S,
    sectionIndex: Int? = nil,
    validationMode: HTTPHeaderFieldParameterParser<S>.Configuration.Mode = .default
  ) {
    switch validationMode {
    case .default:
      guard attribute.utf8.allSatisfy(\._isAvailableInHTTPToken) else {
        return nil
      }
    case .mimeCompatible:
      guard attribute.utf8.allSatisfy(\._isAvailableInParameterNameForMIME) else {
        return nil
      }
    }
    self.init(_validatedAttribute: ASCIICaseInsensitiveString(attribute), sectionIndex: sectionIndex)
  }
}

extension HTTPHeaderFieldParameter.ExtendedName {
  @inlinable
  public init?<S>(
    attribute: S,
    sectionIndex: Int? = nil,
    validationMode: HTTPHeaderFieldParameterParser<S>.Configuration.Mode = .default
  ) {
    guard let baseName = HTTPHeaderFieldParameter.Name(
      attribute: attribute,
      sectionIndex: sectionIndex,
      validationMode: validationMode
    ) else {
      return nil
    }
    self.init(_baseName: baseName)
  }
}

extension HTTPHeaderFieldParameter: _InitializableWithParser, LosslessStringConvertible {
  public var description: String {
    switch self._nameValuePair {
    case .regular(name: let name, value: let value):
      return "\(name.description)=\(value.description)"
    case .extended(name: let name, value: let value):
      return "\(name.description)=\(value.description)"
    case .nonInitialExtended(name: let name, value: let value):
      return "\(name.description)=\(value.description)"
    }
  }

  public init?<S>(_ description: S) where S: StringProtocol {
    self.init(description, parser: HTTPHeaderFieldParameterParser<S>.self)
  }
}

// MARK: - Value dividers

extension HTTPHeaderFieldParameter.Value {
  /// This function divides the value into two values,
  /// where the count of first one's UTF-8 reporesentation is less than or equal to `maxCount`.
  ///
  /// - Parameters:
  ///   * maxCount: The maximum count of the first part's UTF-8 representation which should be greater than 3.
  ///
  /// - Returns: Two values.
  ///            The second one may be `nil` if the count of the whole value is less than or equal to `maxCount`.
  public func divide(
    whereFirstPartMaxUTF8Count maxCount: Int
  ) -> (HTTPHeaderFieldParameter.Value, HTTPHeaderFieldParameter.Value?) {
    switch self._value {
    case .token(let token):
      precondition(maxCount > 0, "`maxCount` must be a positive value.")

      let tokenUTF8 = token._utf8
      Fast_Path: if tokenUTF8.withContiguousStorageIfAvailable({
        $0.count <= maxCount
      }) == true {
        return (self, nil)
      }

      if let divisionIndex = tokenUTF8.index(
        tokenUTF8.startIndex,
        offsetBy: maxCount,
        limitedBy: tokenUTF8.endIndex
      ) {
        return (
          HTTPHeaderFieldParameter.Value(_token: token._subsequence(in: ..<divisionIndex)),
          HTTPHeaderFieldParameter.Value(_token: token._subsequence(in: divisionIndex...)),
        )
      }
      return (self, nil)
    case .quotedString(let quotedString):
      let divided = quotedString.divide(whereFirstPartMaxUTF8Count: maxCount)
      return (
        HTTPHeaderFieldParameter.Value(quotedString: divided.0),
        divided.1.map({ HTTPHeaderFieldParameter.Value(quotedString: $0) })
      )
    }
  }
}

extension HTTPHeaderFieldParameter.ExtendedValue {
  /// This function divides the value into two values,
  /// where the count of first one's UTF-8 reporesentation is less than or equal to `maxCount`.
  ///
  /// - Returns: Two values if possible.
  ///            `nil` may be returned if `maxCount` is smaller than
  ///            the length of "`<string encoding>'<language tag>'`" `+ 3`.
  public func divide(
    whereFirstPartMaxUTF8Count maxCount: Int
  ) -> (
    HTTPHeaderFieldParameter.ExtendedValue,
    HTTPHeaderFieldParameter.InformationlessExtendedValue?
  )? {
    let stringEncodingUTF8Count = self.stringEncodingDescription.utf8.count
    let languageTagUTF8Count = self.languageTagDescription?.description.utf8.count ?? 0
    let infoCount = stringEncodingUTF8Count + languageTagUTF8Count + 2
    let percentEncodedStringMaxCount = maxCount - infoCount
    guard percentEncodedStringMaxCount >= 3 else {
      return nil
    }
    let endIndex = self.percentEncodedValue.endIndex(whereMaxUTF8Count: percentEncodedStringMaxCount)
    if self.percentEncodedValue.endIndex == endIndex {
      return (self, nil)
    }
    let firstPercentEncodedString = self.percentEncodedValue[..<endIndex]
    let secondPercentEncodedString = self.percentEncodedValue[endIndex...]
    return (
      HTTPHeaderFieldParameter.ExtendedValue(_validated: (
        self.stringEncodingDescription,
        self.languageTagDescription,
        firstPercentEncodedString
      )),
      HTTPHeaderFieldParameter.InformationlessExtendedValue(
        percentEncodedValue: secondPercentEncodedString
      )
    )
  }
}

extension HTTPHeaderFieldParameter.InformationlessExtendedValue {
  /// This function divides the value into two values,
  /// where the count of first one's UTF-8 reporesentation is less than or equal to `maxCount`.
  ///
  /// - Parameters:
  ///   * maxCount: The maximum count of the first part's UTF-8 representation which should be greater than 2.
  ///
  /// - Returns: Two values.
  ///            The second one may be `nil` if the count of the whole value is less than or equal to `maxCount`.
  public func divide(
    whereFirstPartMaxUTF8Count maxCount: Int
  ) -> (
    HTTPHeaderFieldParameter.InformationlessExtendedValue,
    HTTPHeaderFieldParameter.InformationlessExtendedValue?
  ) {
    precondition(maxCount > 2, "Too small value to divide.")
    let endIndex = self.percentEncodedValue.endIndex(whereMaxUTF8Count: maxCount)
    if endIndex == self.percentEncodedValue.endIndex {
      return (self, nil)
    }
    let firstPercentEncodedString = self.percentEncodedValue[..<endIndex]
    let secondPercentEncodedString = self.percentEncodedValue[endIndex...]
    return (
      HTTPHeaderFieldParameter.InformationlessExtendedValue(
        percentEncodedValue: firstPercentEncodedString
      ),
      HTTPHeaderFieldParameter.InformationlessExtendedValue(
        percentEncodedValue: secondPercentEncodedString
      ),
    )
  }
}


// MARK: - The List

/// A list of header field parameters.
public struct HTTPHeaderFieldParameterList: Sendable {
  public typealias Name = HTTPHeaderFieldParameter.Name
  public typealias ExtendedName = HTTPHeaderFieldParameter.ExtendedName
  public typealias Value = HTTPHeaderFieldParameter.Value
  public typealias ExtendedValueProtocol = HTTPHeaderFieldParameter.ExtendedValueProtocol
  public typealias ExtendedValue = HTTPHeaderFieldParameter.ExtendedValue
  public typealias InformationlessExtendedValue = HTTPHeaderFieldParameter.InformationlessExtendedValue


  /// All parameters.
  public private(set) var allParameters: [HTTPHeaderFieldParameter]

  public enum FixMode: Sendable, Equatable {
    /// Combine values to remove sectioned parameters as far as possible.
    ///
    ///
    /// ## How to fix(compromise)
    ///
    /// **Principle:** Don't use sectioned parameters.
    ///
    /// ### Conditions
    ///
    /// For each attribute:
    ///
    /// - 1. Non-sectioned parameters exist?
    ///   + 1-A. A regular parameter exists?
    ///   + 1-B. An extended parameter exists?
    /// - 2. Sectioned parameters exist?
    ///   + 2-A. Only regular parameters? (Or they can be converted into one regular paramter?)
    ///
    ///  | 1.  | 1-A. | 1-B. | 2.  | 2-A. | Pattern |
    ///  |-----|------|------|-----|------|---------|
    ///  | Yes | Yes  | Yes  | No  | n/a  | ⅰ      |
    ///  | Yes | Yes  | No   | No  | n/a  | ⅰ      |
    ///  | Yes | No   | Yes  | No  | n/a  | ⅰ      |
    ///  | Yes | Yes  | Yes  | Yes | Yes  | ⅱ      |
    ///  | Yes | Yes  | Yes  | Yes | No   | ⅱ      |
    ///  | Yes | Yes  | No   | Yes | Yes  | ⅲ      |
    ///  | Yes | Yes  | No   | Yes | No   | ⅲ      |
    ///  | Yes | No   | Yes  | Yes | Yes  | ⅳ      |
    ///  | Yes | No   | Yes  | Yes | No   | ⅴ      |
    ///  | No  | n/a  | n/a  | Yes | Yes  | ⅵ      |
    ///  | No  | n/a  | n/a  | Yes | No   | ⅵ      |
    ///  | No  | n/a  | n/a  | No  | n/a  | Never   |
    ///
    ///
    /// ### Patterns
    ///
    /// #### Pattern ⅰ
    ///
    /// No fix is needed.
    ///
    /// #### Pattern ⅱ
    ///
    /// Sectioned parameters are dicarded.
    ///
    /// #### Pattern ⅲ
    ///
    /// Sectioned parameters are combined and remain as an extended parameter.
    ///
    /// #### Pattern ⅳ
    ///
    /// Sectioned parameters are combined into one regular parameter.
    ///
    /// #### Pattern ⅴ
    ///
    /// Either:
    /// - Pattern ⅴ-a: The non-sectioned extended parameter is converted to a regular parameter if possible.
    /// - Pattern ⅴ-b: The sectioned parameters are converted to one regular parameter if possible.
    /// - Pattern ⅴ-c: The sectioned parameters are discarded.
    ///
    /// #### Pattern ⅵ
    ///
    /// Sectioned parameters are combined into one regular/extended parameter.
    case http

    /// Split values to satisfy line limits of MIME headers and make section indices "strideable".
    ///
    /// With this mode, the count of `<name>=<value>` will be less than or equal to 74.
    ///
    /// ## For each attribute:
    ///
    /// A non-sectioned regular parameter can coexist with (non-)sectioned extended parameter(s).
    /// When one regular parameter must be splitted to sectioned parameters,
    /// (non-)sectioned extended parameter(s) will be discarded.
    case mime
  }

  private var _fixed: FixMode? = nil

  /// A dicrionary: `attribute` (-> `sectionIndex`) -> `isExtended` -> parameter
  internal private(set) var _groupedParameters: (
    nonSectioned: [
      ASCIICaseInsensitiveString /* attribute */ : [
        Bool /* isExtended */ : HTTPHeaderFieldParameter
      ]
    ],
    sectioned: [
      ASCIICaseInsensitiveString /* attribute */ : [
        Int /* sectionIndex */ : [
          Bool /* isExtended */ : HTTPHeaderFieldParameter
        ]
      ]
    ]
  ) {
    didSet {
      _fixed = nil
    }
  }

  @inlinable
  public var isEmpty: Bool {
    return allParameters.isEmpty
  }

  public mutating func append(_ parameter: HTTPHeaderFieldParameter) {
    if let sectionIndex = parameter.sectionIndex {
      _groupedParameters.sectioned[
        parameter.attribute, default: [:]
      ][
        sectionIndex, default: [:]
      ][
        parameter.isExtended
      ] = parameter
    } else {
      _groupedParameters.nonSectioned[
        parameter.attribute, default: [:]
      ][
        parameter.isExtended
      ] = parameter
    }
    allParameters.append(parameter)
  }

  @inlinable
  public mutating func append<S>(contentsOf parameters: S)
  where S: Sequence, S.Element == HTTPHeaderFieldParameter {
    for parameter in parameters {
      self.append(parameter)
    }
  }

  private func _parametersGroupedByExtended(
    forAttribute attribute: ASCIICaseInsensitiveString,
    sectionIndex: Int?
  ) -> [Bool: HTTPHeaderFieldParameter]? {
    if let sectionIndex = sectionIndex {
      return _groupedParameters.sectioned[attribute]?[sectionIndex]
    } else {
      return _groupedParameters.nonSectioned[attribute]
    }
  }

  /// Returns the parameter whose attribute is `attribute`.
  /// An extended parameter is returned if available.
  public subscript(
    attribute: ASCIICaseInsensitiveString,
    sectionIndex sectionIndex: Int? = nil
  ) -> HTTPHeaderFieldParameter? {
    guard let groupedByExtended = _parametersGroupedByExtended(
      forAttribute: attribute,
      sectionIndex: sectionIndex
    ) else {
      return nil
    }
    return groupedByExtended[true] ?? groupedByExtended[false]
  }

  public subscript(_ name: HTTPHeaderFieldParameter.Name) -> HTTPHeaderFieldParameter.Value? {
    return _parametersGroupedByExtended(
      forAttribute: name.attribute, sectionIndex: name.sectionIndex
    )?[false]?.regularValue
  }

  public subscript(_ name: HTTPHeaderFieldParameter.ExtendedName) -> (any ExtendedValueProtocol)? {
    guard let parameter = _parametersGroupedByExtended(
      forAttribute: name.attribute, sectionIndex: name.sectionIndex
    )?[true] else {
      return nil
    }
    return parameter.extendedValue ?? parameter.informationlessExtendedValue
  }

  @inlinable
  public subscript(extended name: HTTPHeaderFieldParameter.Name) -> (any ExtendedValueProtocol)? {
    return self[HTTPHeaderFieldParameter.ExtendedName(_baseName: name)]
  }

  private func _createCombinedValue(from sections: [Int: [Bool: HTTPHeaderFieldParameter]]) -> String? {
    if sections.isEmpty {
      return nil
    }

    var result = ""

    var defaultStringEncodingForExtendedValue: String.Encoding? = nil
    var buffer: Data? = nil
    func __flushBuffer() {
      defer {
        buffer = nil
      }
      guard let nonnilBuffer = buffer, let decodedString = String(
        data: nonnilBuffer,
        encoding: defaultStringEncodingForExtendedValue ?? .utf8
      ) else {
        return
      }
      result += decodedString
    }

    for (_, groupedByExtended) in sections.sorted(by: { $0.key < $1.key }) {
      guard let parameter = groupedByExtended[true] ?? groupedByExtended[false] else {
        continue
      }

      if let regularValue = parameter.regularValue {
        __flushBuffer()
        result += regularValue.content
      } else if let extendedValue = parameter.extendedValue {
        __flushBuffer()
        buffer = extendedValue.decodedValueData // Initialize the buffer
        defaultStringEncodingForExtendedValue = extendedValue.stringEncoding
      } else if let informationlessExtendedValue = parameter.informationlessExtendedValue {
        let nextData = informationlessExtendedValue.decodedValueData
        if (buffer?.append(nextData)).isNil { // Actually `buffer` shouldn't `nil` here though.
          buffer = nextData
        }
      }
    }
    __flushBuffer()

    return result
  }

  /// A combined string value that is specified by `attribute`
  /// and is sectioned into several parameters.
  ///
  /// - NOTE:
  ///     This function returns combined value as long as possible even if some values are missing.
  public func combinedValue(for attribute: ASCIICaseInsensitiveString) -> String? {
    guard let sections = self._groupedParameters.sectioned[attribute] else {
      return nil
    }
    return _createCombinedValue(from: sections)
  }

  public init() {
    self.allParameters = []
    self._groupedParameters = ([:], [:])
  }

  public init<S>(_ parameters: S) where S: Sequence, S.Element == HTTPHeaderFieldParameter {
    self.init()
    for parameter in parameters {
      self.append(parameter)
    }
  }

  private func _fixedForHTTP() -> HTTPHeaderFieldParameterList? {
    FAST_PATH: if _groupedParameters.sectioned.isEmpty {
      return self
    }

    var combinedExtendedParameterCache: [ASCIICaseInsensitiveString: HTTPHeaderFieldParameter] = [:]
    enum __CombinedType { case regular, extended }
    func __combineSectionedParameters(
      _ sectionedParameters: [Int: [Bool: HTTPHeaderFieldParameter]],
      into type: __CombinedType,
      for attribute: ASCIICaseInsensitiveString
    ) -> HTTPHeaderFieldParameter? {
      var sectionedParametersAreAllRegular = true
      let sortedSectionedParameters = sectionedParameters.sorted(by: {
        assert($0.value.keys.contains(true) || $0.value.keys.contains(false))
        if sectionedParametersAreAllRegular {
          if $0.value.keys.contains(true) || $1.value.keys.contains(true) {
            sectionedParametersAreAllRegular = false
          }
        }
        return $0.key < $1.key
      })
      let regularName = Name(_validatedAttribute: attribute, sectionIndex: nil)

      func __intoExtended() -> HTTPHeaderFieldParameter? {
        if let extended = combinedExtendedParameterCache[attribute] {
          return extended
        }

        var combinedPercentEncodedUTF8String = ""
        var currentStringEncoding: String.Encoding? = nil

        func __append(addingPercentEncoding string: String) {
          combinedPercentEncodedUTF8String += string.addingPercentEncoding(
            whereAllowedASCIICharacters: \._isAvailableInMIMECharsetInExtendedValue
          )
        }

        var nonUTF8DecodedValueBuffer: Data? = nil
        func __flushBuffer() {
          defer {
            nonUTF8DecodedValueBuffer = nil
          }
          guard let buffer = nonUTF8DecodedValueBuffer,
                let decodedString = String(data: buffer, encoding: currentStringEncoding ?? .utf8)
          else {
            return
          }
          __append(addingPercentEncoding: decodedString)
        }

        for (_, groupedByExtended) in sortedSectionedParameters {
          guard let parameter = groupedByExtended[true] ?? groupedByExtended[false] else {
            continue
          }
          if let regularValue = parameter.regularValue {
            __flushBuffer()
            __append(addingPercentEncoding: regularValue.content)
          } else if let extendedValue = parameter.extendedValue {
            __flushBuffer()
            currentStringEncoding = extendedValue.stringEncoding
            if currentStringEncoding == .utf8 {
              combinedPercentEncodedUTF8String += extendedValue.percentEncodedValue.encodedString
            } else {
              nonUTF8DecodedValueBuffer = extendedValue.decodedValueData
            }
          } else if let informationlessExtendedValue = parameter.informationlessExtendedValue {
            if currentStringEncoding == .utf8 {
              combinedPercentEncodedUTF8String += informationlessExtendedValue.percentEncodedValue.encodedString
            } else {
              let nextData = informationlessExtendedValue.decodedValueData
              if (nonUTF8DecodedValueBuffer?.append(nextData)).isNil {
                nonUTF8DecodedValueBuffer = nextData
              }
            }
          }
        }
        __flushBuffer()

        if combinedPercentEncodedUTF8String.isEmpty {
          return nil
        }
        let extendedName = ExtendedName(_baseName: regularName)
        let extendedParameter = HTTPHeaderFieldParameter.extended(
          name: extendedName,
          value: ExtendedValue(
            _validated: (
              stringEncodingDescription: "UTF-8",
              languageTagDescription: nil,
              percentEncodedValue: PercentEncodedString(
                encodedString: combinedPercentEncodedUTF8String
              )
            )
          )
        )
        combinedExtendedParameterCache[attribute] = extendedParameter
        return extendedParameter
      } // __intoExtended

      switch type {
      case .regular:
        if sectionedParametersAreAllRegular {
          var combinedRegularValue = sortedSectionedParameters.first!.value[false]!.regularValue!
          for (_ /* sectionIndex */, groupedByExtended) in sortedSectionedParameters.dropFirst() {
            combinedRegularValue.append(groupedByExtended[false]!.regularValue!)
          }
          return .regular(name: regularName, value: combinedRegularValue)
        } else if let combinedExtendedParameter = __intoExtended() {
          guard let quotedString = combinedExtendedParameter.value.flatMap({
            QuotedString(quoting: $0)
          }) else {
            return nil
          }
          return .regular(name: regularName, value: Value(quotedString: quotedString))
        }
        return nil
      case .extended:
        return __intoExtended()
      }
    } // __combineSectionedParameters(_:into:for:)

    // "Patterns" are described in the doc of `FixMode.http`.

    var newList = HTTPHeaderFieldParameterList()

    // Pattern ⅰ〜ⅴ
    ITERATE_NONSECTIONED_PARAMETERS: for (
      attribute,
      nonSectionedParametersGroupedByExtended
    ) in _groupedParameters.nonSectioned {
      guard let sectionedParameters = _groupedParameters.sectioned[attribute],
            !sectionedParameters.isEmpty else {
        `Pattern ⅰ`: do {
          newList.append(contentsOf: nonSectionedParametersGroupedByExtended.values)
          continue ITERATE_NONSECTIONED_PARAMETERS
        }
      }

      // Pattern ⅱ〜ⅴ
      switch (nonSectionedParametersGroupedByExtended[false], nonSectionedParametersGroupedByExtended[true]) {
      case (let nonSectionedRegular?, let nonSectionedExtended?):
        `Pattern ⅱ`: do {
          newList.append(nonSectionedRegular)
          newList.append(nonSectionedExtended)
          continue ITERATE_NONSECTIONED_PARAMETERS
        }
      case (let nonSectionedRegular?, nil):
        `Pattern ⅲ`: do {
          newList.append(nonSectionedRegular)
          
          guard let combinedValue = _createCombinedValue(from: sectionedParameters) else {
            continue ITERATE_NONSECTIONED_PARAMETERS
          }
          let extValue = ExtendedValue(_validated: (
            stringEncodingDescription: "UTF-8",
            languageTagDescription: nil,
            percentEncodedValue: combinedValue.percentEncodedString(
              whereAllowedASCIICharacters: \._isAvailableInExtendedValueWithoutPercentEncoding
            )
          ))
          let extName = ExtendedName(
            _baseName: Name(_validatedAttribute: attribute, sectionIndex: nil)
          )
          let extended = HTTPHeaderFieldParameter(name: extName, value: extValue)
          newList.append(extended)
          continue ITERATE_NONSECTIONED_PARAMETERS
        }
      case (nil, let nonSectionedExtended?):
        `Pattern ⅳ`: if let combinedRegularParameter = __combineSectionedParameters(
          sectionedParameters,
          into: .regular,
          for: attribute
        ) {
          newList.append(nonSectionedExtended)
          newList.append(combinedRegularParameter)
          continue ITERATE_NONSECTIONED_PARAMETERS
        }

        `Pattern ⅴ`: do {
          `Pattern ⅴ-a`: if let nonSectionedValue = nonSectionedExtended.value,
                             let quotedValue = QuotedString(quoting: nonSectionedValue) {
            newList.append(
              .regular(
                name: Name(_validatedAttribute: attribute, sectionIndex: nil),
                value: Value(quotedString: quotedValue)
              )
            )
            if let combinedExtendedParameter = __combineSectionedParameters(
              sectionedParameters,
              into: .extended,
              for: attribute
            ) {
              newList.append(combinedExtendedParameter)
            }
            continue ITERATE_NONSECTIONED_PARAMETERS
          }

          `Pattern ⅴ-b`: if let regularParameter = __combineSectionedParameters(
            sectionedParameters,
            into: .regular,
            for: attribute
          ) {
            newList.append(regularParameter)
            newList.append(nonSectionedExtended)
            continue ITERATE_NONSECTIONED_PARAMETERS
          }

          `Pattern ⅴ-c`: do {
            newList.append(nonSectionedExtended)
            continue ITERATE_NONSECTIONED_PARAMETERS
          }
        }
      case (nil, nil):
        fatalError("Unexpected path.")
      }
    } // ITERATE_NONSECTIONED_PARAMETERS

    `Pattern ⅵ`: for (attribute, sectionedParameters) in _groupedParameters.sectioned {
      if _groupedParameters.nonSectioned.keys.contains(attribute) {
        continue
      }
      if let regularParameter = __combineSectionedParameters(
        sectionedParameters,
        into: .regular,
        for: attribute
      ) {
        newList.append(regularParameter)
      }
      if let extendedParameter = __combineSectionedParameters(
        sectionedParameters,
        into: .extended,
        for: attribute
      ) {
        newList.append(extendedParameter)
      }
    } // Pattern ⅵ

    return newList
  }

  private func _fixedForMIME() -> HTTPHeaderFieldParameterList? {
    fatalError("Unimplemented.")
  }

  /// Creates a new list that would be available for the specification identified by `mode`.
  ///
  /// - Returns: A fixed list if possible.
  public func fixed(for mode: FixMode) -> HTTPHeaderFieldParameterList? {
    if _fixed == mode {
      return self
    }

    guard var fixedList = switch mode {
    case .http: _fixedForHTTP()
    case .mime: _fixedForMIME()
    } else {
      return nil
    }
    fixedList._fixed = mode
    return fixedList
  }
}

extension HTTPHeaderFieldParameterList: Sequence {
  public typealias Element = HTTPHeaderFieldParameter
  public typealias Iterator = Array<Element>.Iterator

  public func makeIterator() -> Array<Element>.Iterator {
    self.allParameters.makeIterator()
  }
}

internal struct _SemicolonSeparatorParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  typealias Output = Input.SubSequence

  let input: Input
  let utf8: Input.UTF8View
  
  init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
    var index = utf8.startIndex
    if let (_, spaceEndIndex) = LinearWhitespaceParser<Input>.parse(self.input) {
      index = spaceEndIndex
    }
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isSemicolon) else {
      return nil
    }
    if let (_, spaceEndIndex) = LinearWhitespaceParser<Input.SubSequence>.parse(self.input[index...]) {
      index = spaceEndIndex
    }
    return (input[..<index], index)
  }
}

public struct HTTPHeaderFieldParameterListParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameterList
  public typealias Configuration = HTTPHeaderFieldParameterParser<Input.SubSequence>.Configuration

  let input: Input
  let utf8: Input.UTF8View

  public let configuration: Configuration?

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  public init(input: Input, mode: Configuration.Mode) {
    self.init(input: input, configuration: Configuration(mode: mode))
  }

  public func parse() -> (output: HTTPHeaderFieldParameterList, endIndex: Input.Index)? {
    var index = utf8.startIndex

    func __consumeSeparator() -> Bool {
      if let (_, sepEndIndex) = _SemicolonSeparatorParser<Input.SubSequence>.parse(self.input[index...]) {
        index = sepEndIndex
        return true
      }
      return false
    }

    var list = HTTPHeaderFieldParameterList()
    while index < utf8.endIndex {
      while __consumeSeparator() {}
      guard let parameterResult = HTTPHeaderFieldParameterParser<Input.SubSequence>.parse(
        self.input[index...], configuration: self.configuration
      ) else {
        break
      }
      list.append(parameterResult.output)
      index = parameterResult.endIndex
    }

    guard index > utf8.startIndex else {
      return nil
    }

    return (list, index)
  }
}

extension HTTPHeaderFieldParameterList: _InitializableWithParser, LosslessStringConvertible {
  public var description: String {
    return self.allParameters.map(\.description).joined(separator: "; ")
  }

  public init?<S>(_ description: S) where S: StringProtocol {
    self.init(description, parser: HTTPHeaderFieldParameterListParser<S>.self)
  }
}
