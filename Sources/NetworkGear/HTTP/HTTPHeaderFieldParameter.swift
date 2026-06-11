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
  }

  private enum _NameValuePair: Sendable, Equatable, Hashable {
    case regular(name: Name, value: Value)
    case extended(name: ExtendedName, value: ExtendedValue)
  }

  private let _nameValuePair: _NameValuePair

  /// A Boolean value indicating whether or not the value is an "extended value".
  public var isExtended: Bool {
    if case .extended = _nameValuePair {
      return true
    }
    return false
  }

  /// A string that is a core part of the name.
  public var attribute: ASCIICaseInsensitiveString {
    switch _nameValuePair {
    case .regular(let name, _):
      return name.attribute
    case .extended(let name, _):
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
    }
  }

  public var nameDescription: String {
    switch _nameValuePair {
    case .regular(let name, _):
      return name.description
    case .extended(let name, _):
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

  /// A string of the value.
  /// `nil` is returned only if the value is percent-encoded and decoding fails.
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
    }
  }

  public var valueDescription: String {
    switch _nameValuePair {
    case .regular(_, let value):
      return value.description
    case .extended(_, let value):
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

  /// Returns a regular parameter.
  public static func regular(name: Name, value: Value) -> HTTPHeaderFieldParameter {
    return .init(name: name, value: value)
  }

  /// Returns an extended parameter.
  public static func extended(name: ExtendedName, value: ExtendedValue) -> HTTPHeaderFieldParameter {
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


/// A parser for `HTTPHeaderFieldParameter`.
public class HTTPHeaderFieldParameterParser<Input>: @unchecked Sendable, StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameter

  let string: Input
  let utf8: Input.UTF8View

  public required init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  private func _parseName() -> (name: _ParameterName, endIndex: Input.Index)? {
    guard let (name, endIndex) =  _HTTPHeaderFieldParameterNameParser<Input>.parse(self.string) else {
      return nil
    }
    return (name, endIndex)
  }

  public final class MIMECompatible: HTTPHeaderFieldParameterParser, @unchecked Sendable {
    override func _parseName() -> (name: _ParameterName, endIndex: Input.Index)? {
      guard let (name, endIndex) = _MIMECompatibleParameterNameParser<Input>.parse(self.string) else {
        return nil
      }
      return (name, endIndex)
    }
  }

  public func parse() -> (output: HTTPHeaderFieldParameter, endIndex: Input.Index)? {
    guard let (name, nameEndIndex) = self._parseName() else {
      return nil
    }

    var index = nameEndIndex
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isEqualSign) else {
      return nil
    }

    switch name {
    case .regular(let name):
      guard let (value, endIndex) = HTTPHeaderFieldParameterValueParser<Input.SubSequence>.parse(
        self.string[index...]
      ) else {
        return nil
      }
      return (
        output: HTTPHeaderFieldParameter(name: name, value: value),
        endIndex: endIndex
      )
    case .extended(let extendedName):
      guard let (extendedValue, endIndex) = ExtendedParameterValueParser<Input.SubSequence>.parse(
        self.string[index...]
      ) else {
        return nil
      }
      return (
        output: HTTPHeaderFieldParameter(name: extendedName, value: extendedValue),
        endIndex: endIndex
      )
    }
  }
}

extension HTTPHeaderFieldParameter: _InitializableWithParser, LosslessStringConvertible {
  public var description: String {
    switch self._nameValuePair {
    case .regular(name: let name, value: let value):
      return "\(name.description)=\(value.description)"
    case .extended(name: let name, value: let value):
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

  /// A dicrionary: `attribute` -> `sectionIndex` -> `isExtended` -> parameter
  internal private(set) var _groupedParameters: [
    ASCIICaseInsensitiveString: [
      Optional<Int>: [Bool: HTTPHeaderFieldParameter]
    ]
  ]

  @inlinable
  public var isEmpty: Bool {
    return allParameters.isEmpty
  }

  public mutating func append(_ parameter: HTTPHeaderFieldParameter) {
    _groupedParameters[
      parameter.attribute, default: [:]
    ][
      parameter.sectionIndex, default: [:]
    ][parameter.isExtended] = parameter
    allParameters.append(parameter)
  }

  /// Returns the parameter whose attribute is `attribute`.
  /// An extended parameter is returned if available.
  public subscript(
    attribute: ASCIICaseInsensitiveString,
    sectionIndex sectionIndex: Int? = nil
  ) -> HTTPHeaderFieldParameter? {
    guard let groupedBySection = self._groupedParameters[attribute],
          let groupedByExtended = groupedBySection[sectionIndex] else {
      return nil
    }
    return groupedByExtended[true] ?? groupedByExtended[false]
  }

  public subscript(_ name: HTTPHeaderFieldParameter.Name) -> HTTPHeaderFieldParameter.Value? {
    return _groupedParameters[name.attribute]?[name.sectionIndex]?[false]?.regularValue
  }

  public subscript(_ name: HTTPHeaderFieldParameter.ExtendedName) -> HTTPHeaderFieldParameter.ExtendedValue? {
    return _groupedParameters[name.attribute]?[name.sectionIndex]?[true]?.extendedValue
  }

  @inlinable
  public subscript(extended name: HTTPHeaderFieldParameter.Name) -> HTTPHeaderFieldParameter.ExtendedValue? {
    return self[HTTPHeaderFieldParameter.ExtendedName(_baseName: name)]
  }

  /// A combined string value that is specified by `attribute`
  /// and is sectioned into several parameters.
  ///
  /// - NOTE:
  ///     This function returns combined value as long as possible even if some values are missing.
  public func combinedValue(for attribute: ASCIICaseInsensitiveString) -> String? {
    guard let groupedBySection = self._groupedParameters[attribute] else {
      return nil
    }
    let sections: [Int: [Bool: HTTPHeaderFieldParameter]] = groupedBySection.reduce(into: [:]) {
      guard let sectionIndex = $1.key else {
        return
      }
      $0[sectionIndex] = $1.value
    }
    if sections.isEmpty {
      return nil
    }

    var result = ""
    for (_, groupedByExtended) in sections.sorted(by: { $0.key < $1.key }) {
      guard let value = groupedByExtended[true]?.value ?? groupedByExtended[false]?.value else {
        continue
      }
      result += value
    }
    return result
  }

  public init() {
    self.allParameters = []
    self._groupedParameters = [:]
  }

  public init<S>(_ parameters: S) where S: Sequence, S.Element == HTTPHeaderFieldParameter {
    self.init()
    for parameter in parameters {
      self.append(parameter)
    }
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

  let string: Input
  let utf8: Input.UTF8View
  
  init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
    var index = utf8.startIndex
    if let (_, spaceEndIndex) = LinearWhitespaceParser<Input>.parse(self.string) {
      index = spaceEndIndex
    }
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isSemicolon) else {
      return nil
    }
    if let (_, spaceEndIndex) = LinearWhitespaceParser<Input.SubSequence>.parse(self.string[index...]) {
      index = spaceEndIndex
    }
    return (string[..<index], index)
  }
}

public struct HTTPHeaderFieldParameterListParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameterList

  let string: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  public func parse() -> (output: HTTPHeaderFieldParameterList, endIndex: Input.Index)? {
    var index = utf8.startIndex

    func __consumeSeparator() -> Bool {
      if let (_, sepEndIndex) = _SemicolonSeparatorParser<Input.SubSequence>.parse(self.string[index...]) {
        index = sepEndIndex
        return true
      }
      return false
    }

    var list = HTTPHeaderFieldParameterList()
    while index < utf8.endIndex {
      while __consumeSeparator() {}
      guard let parameterResult = HTTPHeaderFieldParameterParser<Input.SubSequence>.parse(
        self.string[index...]
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
