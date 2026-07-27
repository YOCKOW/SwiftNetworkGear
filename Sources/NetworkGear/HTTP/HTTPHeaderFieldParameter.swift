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
      case token(HTTPTokenString)
      case quotedString(QuotedString)

      static func ==(lhs: _Value, rhs: _Value) -> Bool {
        switch (lhs, rhs) {
        case (.token(let lToken), .token(let rToken)): return lToken == rToken
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
      case .token(let token): return token._string
      case .quotedString(let quotedString): return quotedString.content
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

    /// Create a new value by adding leading/trailing double quotation marks to the given `value`.
    ///
    /// - Returns: `nil` if `value` contains any byte which cannot be used in quoted string.
    public init?<S>(quoting value: S) where S: StringProtocol {
      guard let quoted = value._quotedString else {
        return  nil
      }
      self.init(quotedString: QuotedString(quotedString: quoted))
    }
  }

  public struct ExtendedValue: Sendable, Equatable, Hashable, CustomStringConvertible {
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
          stringEncodingDescription,
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
  public struct InformationlessExtendedValue: Sendable, Equatable, Hashable, CustomStringConvertible {
    /// Percent-encoded value.
    public let percentEncodedValue: PercentEncodedString

    public var description: String { percentEncodedValue.encodedString }

    public func decodedValue(usingStringEncoding stringEncoding: String.Encoding) -> String? {
      return percentEncodedValue.decodedString(usingStringEncoding: stringEncoding)
    }

    public var decodedValueData: Data {
      return percentEncodedValue.decodedData
    }

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
        return token._string
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


// MARK: - The List

/// A list of header field parameters.
public struct HTTPHeaderFieldParameterList: Sendable {
  /// All parameters.
  public private(set) var allParameters: [HTTPHeaderFieldParameter]

  public enum FixMode: Sendable, Equatable {
    /// Combine values to remove sectioned parameters.
    case http

    /// Split values to satisfy line limits of MIME headers and make section indices "strideable".
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

  public subscript(_ name: HTTPHeaderFieldParameter.ExtendedName) -> HTTPHeaderFieldParameter.ExtendedValue? {
    return _parametersGroupedByExtended(
      forAttribute: name.attribute, sectionIndex: name.sectionIndex
    )?[true]?.extendedValue
  }

  public subscript(_ name: HTTPHeaderFieldParameter.ExtendedName) -> HTTPHeaderFieldParameter.InformationlessExtendedValue? {
    return _parametersGroupedByExtended(
      forAttribute: name.attribute, sectionIndex: name.sectionIndex
    )?[true]?.informationlessExtendedValue
  }

  @inlinable
  public subscript(extended name: HTTPHeaderFieldParameter.Name) -> HTTPHeaderFieldParameter.ExtendedValue? {
    return self[HTTPHeaderFieldParameter.ExtendedName(_baseName: name)]
  }

  @inlinable
  public subscript(extended name: HTTPHeaderFieldParameter.Name) -> HTTPHeaderFieldParameter.InformationlessExtendedValue? {
    return self[HTTPHeaderFieldParameter.ExtendedName(_baseName: name)]
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
    if sections.isEmpty {
      return nil
    }

    var result = ""
    var defaultStringEncodingForExtendedValue: String.Encoding? = nil
    for (_, groupedByExtended) in sections.sorted(by: { $0.key < $1.key }) {
      guard let parameter = groupedByExtended[true] ?? groupedByExtended[false] else {
        continue
      }

      if let regularValue = parameter.regularValue {
        result += regularValue.content
      } else if let extendedValue = parameter.extendedValue {
        if let valueString = extendedValue.decodedValue {
          result += valueString
        }
        if defaultStringEncodingForExtendedValue.isNil {
           defaultStringEncodingForExtendedValue = extendedValue.stringEncoding
        }
      } else if let informationlessExtendedValue = parameter.informationlessExtendedValue {
        if let valueString = informationlessExtendedValue.decodedValue(
          usingStringEncoding: defaultStringEncodingForExtendedValue ?? .utf8
        ) {
          result += valueString
        }
      }
    }
    return result
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
    fatalError("Unimplemented.")
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
