/* *************************************************************************************************
 MIMEType.swift
   © 2017-2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import Ranges
import yExtensions

/// A parser to parse a string defined as `restricted-name` in
/// [RFC 6838 §4.2](https://datatracker.ietf.org/doc/html/rfc6838#section-4.2).
private struct _MIMETypeRestrictedNameParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  typealias Output = (
    name: Input.SubSequence,
    indexOfFirstPeriod: Input.Index?,
    indexOfLastPlusSign: Input.Index?
  )

  let input: Input
  let utf8: Input.UTF8View

  init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex
    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isAlphanumeric
    ) else {
      return nil
    }

    var count = 0
    var previousIndex = currentIndex
    var indexOfFirstPeriod: Input.Index? = nil
    var indexOfLastPlusSign: Input.Index? = nil
    while let byte = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isAvailableInMIMETypeRestrictedName
    ) {
      guard count < 126 else {
        break
      }
      defer {
        count += 1
        previousIndex = currentIndex
      }
      if byte._isPeriod && indexOfFirstPeriod.isNil && indexOfLastPlusSign.isNil {
        indexOfFirstPeriod = previousIndex
      }
      if byte._isPlusSign {
        indexOfLastPlusSign = previousIndex
      }
    }
    let output: Output = (
      name: input[..<currentIndex],
      indexOfFirstPeriod: indexOfFirstPeriod,
      indexOfLastPlusSign: indexOfLastPlusSign
    )
    return (output, currentIndex)
  }
}



/// # MIMEType
/// Represents MIME Type (a.k.a. media type and content type)
/// Reference: https://en.wikipedia.org/wiki/Media_type
///
/// ## Properties
/// - `type`: Top-level type name as `TopLevelType`
/// - `tree`: Registration tree as `Tree`; nil acceptable
/// - `subtype`: Sub-type name
/// - `suffix`: Suffix
/// - `parameters`: Companion data such as *charset=UTF-8*
public struct MIMEType: Sendable {
  /// A string which is available for type part of MIME Type.
  public struct TopLevelTypeString: Sendable,
                                    Equatable,
                                    Comparable,
                                    Hashable,
                                    CustomStringConvertible,
                                    _InitializableWithParser,
                                    LosslessStringConvertible {
    @usableFromInline internal let _string: ASCIICaseInsensitiveString

    @inlinable
    public static func ==(lhs: TopLevelTypeString, rhs: TopLevelTypeString) -> Bool {
      return lhs._string == rhs._string
    }

    @inlinable
    public static func <(lhs: TopLevelTypeString, rhs: TopLevelTypeString) -> Bool {
      return lhs._string._compare(with: rhs._string) == .orderedAscending
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(_string)
    }

    public var description: String { _string._string }

    @inlinable
    internal init<S>(_validatedString string: S) where S: StringProtocol {
      self._string = ASCIICaseInsensitiveString(string)
    }

    /// A parser to parse a `TopLevelString`.
    public struct Parser<Input>: StringParser where Input: StringProtocol {
      public typealias Output = TopLevelTypeString

      let input: Input
      public init(input: Input) {
        self.input = input
      }

      public mutating func parse() -> (output: Output, endIndex: Input.Index)? {
        guard let result = _MIMETypeRestrictedNameParser<Input>.parse(input) else {
          return nil
        }
        return (
          output: TopLevelTypeString(_validatedString: result.output.name),
          endIndex: result.endIndex
        )
      }
    }

    @inlinable
    public init?<S>(_ description: S) where S: StringProtocol {
      self.init(description, parser: Parser<S>.self)
    }
  }

  public enum TopLevelType: Sendable, RawRepresentable, Equatable, Comparable, Hashable {
    public typealias RawValue = String

    case application
    case audio
    case example
    case font
    case haptics
    case image
    case message
    case model
    case multipart
    case text
    case video
    case unofficial(TopLevelTypeString)

    public static let chemical: TopLevelType = .unofficial(TopLevelTypeString(_validatedString: "chemical"))

    @inlinable
    public var rawValue: String {
      return switch self {
      case .application: "application"
      case .audio: "audio"
      case .example: "example"
      case .font: "font"
      case .haptics: "haptics"
      case .image: "image"
      case .message: "message"
      case .model: "model"
      case .multipart: "multipart"
      case .text: "text"
      case .video: "video"
      case .unofficial(let string): string._string._string
      }
    }

    private var _string: TopLevelTypeString {
      return switch self {
      case .unofficial(let string): string
      default: TopLevelTypeString(_validatedString: self.rawValue)
      }
    }

    public static func ==(lhs: TopLevelType, rhs: TopLevelType) -> Bool {
      return lhs._string == rhs._string
    }

    public static func <(lhs: TopLevelType, rhs: TopLevelType) -> Bool {
      return lhs._string < rhs._string
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(_string)
    }

    public init(string: TopLevelTypeString) {
      switch string._string {
      case "application":
        self = .application
      case "audio":
        self = .audio
      case "example":
        self = .example
      case "font":
        self = .font
      case "haptics":
        self = .haptics
      case "image":
        self = .image
      case "message":
        self = .message
      case "model":
        self = .model
      case "multipart":
        self = .multipart
      case "text":
        self = .text
      case "video":
        self = .video
      default:
        self = .unofficial(string)
      }
    }

    public init?<S>(rawValue: S) where S: StringProtocol {
      guard let string = TopLevelTypeString(rawValue) else {
        return nil
      }
      self.init(string: string)
    }
  }

  public struct TreeString: Sendable,
                            Equatable,
                            Hashable,
                            CustomStringConvertible,
                            _InitializableWithParser,
                            LosslessStringConvertible {
    @usableFromInline let _string: ASCIICaseInsensitiveString

    @inlinable
    public var description: String {
      return _string.description
    }

    @inlinable
    internal init<S>(_validatedString string: S) where S: StringProtocol {
      self._string = ASCIICaseInsensitiveString(string)
    }

    private struct _Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
      typealias Output = TreeString
      let input: Input
      let utf8: Input.UTF8View
      init(input: Input) {
        self.input = input
        self.utf8 = input.utf8
      }
      mutating func parse() -> (output: Output, endIndex: Input.Index)? {
        var currentIndex = self.utf8.startIndex
        guard let _ = self.readCurrentCodeUnit(
          at: &currentIndex,
          ifAllowedCodeUnit: \._isAlphanumeric
        ) else {
          return nil
        }
        _ = self.parseString(
          from: &currentIndex,
          maxCount: 126,
          while: { !$0._isPeriod && !$0._isPlusSign && $0._isAvailableInMIMETypeRestrictedName }
        )
        return (TreeString(_validatedString: input[..<currentIndex]), currentIndex)
      }
    }

    public init?<S>(_ description: S) where S: StringProtocol {
      self.init(description, parser: _Parser<S>.self)
    }
  }

  public enum Tree: Sendable,
                    Equatable,
                    Comparable,
                    Hashable,
                    RawRepresentable {
    public typealias RawValue = String

    /// Vendor Tree (`vnd.`)
    case vendor
    public static let vnd: Tree = .vendor

    /// Personal or Vanity Tree  (`prs.`)
    case personal
    public static let prs: Tree = .personal

    /// Unregistered  Tree  (`x.`)
    case unregistered
    public static let x: Tree = .unregistered

    /// A tree that may be registered in the future.
    case future(TreeString)

    @inlinable
    public var rawValue: String {
      return switch self {
      case .vendor: "vnd"
      case .personal: "prs"
      case .unregistered: "x"
      case .future(let str): str._string._string
      }
    }

    private var _string: TreeString {
      return switch self {
      case .future(let string): string
      default: TreeString(_validatedString: self.rawValue)
      }
    }

    public static func ==(lhs: Tree, rhs: Tree) -> Bool {
      return lhs._string == rhs._string
    }

    public static func <(lhs: Tree, rhs: Tree) -> Bool {
      return lhs._string._string._compare(with: rhs._string._string) == .orderedAscending
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(_string)
    }

    @inlinable
    public init(string: TreeString) {
      switch string._string {
      case "vnd":
        self = .vendor
      case "prs":
        self = .personal
      case "x":
        self = .unregistered
      default:
        self = .future(string)
      }
    }

    @inlinable
    public init?<S>(rawValue: S) where S: StringProtocol {
      guard let string = TreeString(rawValue) else {
        return nil
      }
      self.init(string: string)
    }
  }

  @dynamicMemberLookup
  public struct Subtype: Sendable,
                         Equatable,
                         Hashable,
                         CustomStringConvertible,
                         ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType
    public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

    @usableFromInline let _string: ASCIICaseInsensitiveString

    @inlinable
    public subscript<T>(dynamicMember dynamicMember: KeyPath<String, T>) -> T {
      return _string._string[keyPath: dynamicMember]
    }

    @inlinable
    public var description: String { _string.description }

    @inlinable
    internal init<S>(_validatedString string: S) where S: StringProtocol {
      self._string = ASCIICaseInsensitiveString(string)
    }

    @usableFromInline
    internal init?<S>(_validating string: S) where S: StringProtocol {
      guard let result = _MIMETypeRestrictedNameParser<S>.parse(string) else {
        return nil
      }
      self.init(_validatedString: result.output.name)
    }

    @inlinable
    public init(stringLiteral value: String) {
      guard let instance = Subtype(_validating: value) else {
        fatalError("Unexpected string for `Subtype`?!")
      }
      self = instance
    }
  }

  public struct SuffixString: Sendable,
                              Equatable,
                              Hashable,
                              CustomStringConvertible,
                              _InitializableWithParser,
                              LosslessStringConvertible {
    @usableFromInline let _string: ASCIICaseInsensitiveString

    @inlinable
    public var description: String {
      return _string.description
    }

    @inlinable
    internal init<S>(_validatedString string: S) where S: StringProtocol {
      self._string = ASCIICaseInsensitiveString(string)
    }

    private struct _Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
      typealias Output = SuffixString
      let input: Input
      let utf8: Input.UTF8View
      init(input: Input) {
        self.input = input
        self.utf8 = input.utf8
      }
      mutating func parse() -> (output: Output, endIndex: Input.Index)? {
        var currentIndex = self.utf8.startIndex
        guard let _ = self.readCurrentCodeUnit(
          at: &currentIndex,
          ifAllowedCodeUnit: \._isAlphanumeric
        ) else {
          return nil
        }
        _ = self.parseString(
          from: &currentIndex,
          maxCount: 126,
          while: { !$0._isPlusSign && $0._isAvailableInMIMETypeRestrictedName }
        )
        return (SuffixString(_validatedString: input[..<currentIndex]), currentIndex)
      }
    }

    public init?<S>(_ description: S) where S: StringProtocol {
      self.init(description, parser: _Parser<S>.self)
    }
  }

  /// Structured Syntax Suffix
  ///
  /// - Refernces:
  ///     + [RFC 6838 §4.2.8](https://datatracker.ietf.org/doc/html/rfc6838#section-4.2.8)
  ///     + ["Structured Syntax Suffixes"](https://www.iana.org/assignments/media-type-structured-suffix/media-type-structured-suffix.xml)
  public enum Suffix: Sendable, RawRepresentable, Equatable, Comparable, Hashable {
    public typealias RawValue = String

    /// Extensible Markup Language (XML)
    case xml

    /// JavaScript Object Notation (JSON)
    case json

    /// Basic Encoding Rules (BER) message transfer syntax
    case ber

    /// Concise Binary Object Representation (CBOR)
    case cbor

    /// Distinguished Encoding Rules (DER) message transfer syntax
    case der

    /// Fast Infoset document format
    case fastInfoset
    @available(*, deprecated, renamed: "fastInfoset") public static let fastinfoset: Suffix = .fastInfoset

    /// WAP Binary XML (WBXML) document format
    case wbxml

    /// ZIP file storage and transfer format
    case zip


    /// Type Length Value
    case tlv

    /// JSON Text Sequence
    case jsonTextSequence
    public static let jsonSeq: Suffix = .jsonTextSequence

    /// SQLite3 database
    case sqlite3

    /// JSON Web Token (JWT)
    case jwt

    /// gzip file storage and transfer format
    case gzip

    /// CBOR Sequence
    case cborSequence
    public static let cborSeq: Suffix = .cborSequence

    /// Zstandard
    case zstd

    /// YAML Ain't Markup Language (YAML)
    case yaml

    /// CBOR Object Signing and Encryption (COSE) object
    case cose

    /// CBOR Web Token (CWT)
    case cwt

    /// SD-JWT
    case sdJWT

    /// Comma-Separated Values (CSV)
    case csv

    /// ASN.1 Unaligned Packed Encoding Rules
    case uper

    /// ASN.1 JSON Encoding Rules
    case jer

    /// JSON Web Signature (JWS)
    case jws

    /// SD-CWT
    case sdCWT

    case future(SuffixString)

    @inlinable
    public var rawValue: String {
      return switch self {
      case .xml: "xml"
      case .json: "json"
      case .ber: "ber"
      case .cbor: "cbor"
      case .der: "der"
      case .fastInfoset: "fastinfoset"
      case .wbxml: "wbxml"
      case .zip: "zip"
      case .tlv: "tlv"
      case .jsonTextSequence: "json-seq"
      case .sqlite3: "sqlite3"
      case .jwt: "jwt"
      case .gzip: "gzip"
      case .cborSequence: "cbor-seq"
      case .zstd: "zstd"
      case .yaml: "yaml"
      case .cose: "cose"
      case .cwt: "cwt"
      case .sdJWT: "sd-jwt"
      case .csv: "csv"
      case .uper: "uper"
      case .jer: "jer"
      case .jws: "jws"
      case .sdCWT: "sd-cwt"
      case .future(let string): string._string._string
      }
    }

    private var _string: SuffixString {
      return switch self {
      case .future(let string): string
      default: SuffixString(_validatedString: self.rawValue)
      }
    }

    public static func ==(lhs: Suffix, rhs: Suffix) -> Bool {
      return lhs._string == rhs._string
    }

    public static func <(lhs: Suffix, rhs: Suffix) -> Bool {
      return lhs._string._string._compare(with: rhs._string._string) == .orderedAscending
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(_string)
    }

    @inlinable
    public init(string: SuffixString) {
      switch string._string {
      case "xml": self = .xml
      case "json": self = .json
      case "ber": self = .ber
      case "cbor": self = .cbor
      case "der": self = .der
      case "fastinfoset": self = .fastInfoset
      case "wbxml": self = .wbxml
      case "zip": self = .zip
      case "tlv": self = .tlv
      case "json-seq": self = .jsonTextSequence
      case "sqlite3": self = .sqlite3
      case "jwt": self = .jwt
      case "gzip": self = .gzip
      case "cbor-seq": self = .cborSequence
      case "zstd": self = .zstd
      case "yaml": self = .yaml
      case "cose": self = .cose
      case "cwt": self = .cwt
      case "sd-jwt": self = .sdJWT
      case "csv": self = .csv
      case "uper": self = .uper
      case "jer": self = .jer
      case "jws": self = .jws
      case "sd-cwt": self = .sdCWT
      default: self = .future(string)
      }
    }

    @inlinable
    public init?<S>(rawValue: S) where S: StringProtocol {
      guard let string = SuffixString(rawValue) else {
        return nil
      }
      self.init(string: string)
    }
  }

  /// A parameter name of a media type.
  @dynamicMemberLookup
  public struct ParameterName: Sendable,
                               Equatable,
                               Hashable,
                               Comparable,
                               CustomStringConvertible,
                               _InitializableWithParser,
                               LosslessStringConvertible,
                               ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType
    public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

    @usableFromInline let _string: ASCIICaseInsensitiveString

    public static func <(lhs: ParameterName, rhs: ParameterName) -> Bool {
      return lhs._string._compare(with: rhs._string) == .orderedAscending
    }

    @inlinable
    public var description: String { _string._string }

    @inlinable
    public subscript<T>(dynamicMember dynamicMember: KeyPath<String, T>) -> T {
      return _string._string[keyPath: dynamicMember]
    }

    @inlinable
    internal init<S>(_validatedString string: S) where S: StringProtocol {
      self._string = ASCIICaseInsensitiveString(string)
    }

    /// A parser for a parameter name.
    public struct Parser<Input>: StringParser where Input: StringProtocol {
      public typealias Output = ParameterName

      let input: Input
      public init(input: Input) {
        self.input = input
      }

      public mutating func parse() -> (output: ParameterName, endIndex: Input.Index)? {
        guard let result = _MIMETypeRestrictedNameParser<Input>.parse(input) else {
          return nil
        }
        return (
          output: ParameterName(_validatedString: result.output.name),
          endIndex: result.endIndex
        )
      }
    }

    @usableFromInline
    internal init?<S>(_validating string: S) where S: StringProtocol {
      guard let result = _MIMETypeRestrictedNameParser<S>.parse(string) else {
        return nil
      }
      self.init(_validatedString: result.output.name)
    }

    @inlinable
    public init?<S>(_ description: S) where S: StringProtocol {
      self.init(description, parser: Parser<S>.self)
    }

    @inlinable
    public init(stringLiteral value: String) {
      guard let instance = ParameterName(_validating: value) else {
        fatalError("Unexpected string for `ParameterName`?!")
      }
      self = instance
    }
  }

  public typealias Parameters = Dictionary<ParameterName, String>

  /// Holds properties of `MIMEType` except parameters.
  @usableFromInline
  internal struct _Core: Hashable, Sendable {
    @usableFromInline
    internal var _type: TopLevelType

    @usableFromInline
    internal var _tree: Tree?

    @usableFromInline
    internal var _subtype: Subtype

    @usableFromInline
    internal var _suffix: Suffix?

    internal init(type:TopLevelType, tree:Tree?, subtype:Subtype, suffix:Suffix?) {
      self._type = type
      self._tree = tree
      self._subtype = subtype
      self._suffix = suffix
    }

    @inlinable
    internal static func ==(lhs:_Core, rhs:_Core) -> Bool {
      return (
        lhs._type == rhs._type &&
        lhs._tree == rhs._tree &&
        lhs._subtype == rhs._subtype &&
        lhs._suffix == rhs._suffix
      )
    }

    public func hash(into hasher:inout Hasher) {
      hasher.combine(self._type)
      hasher.combine(self._tree)
      hasher.combine(self._subtype)
      hasher.combine(self._suffix)
    }
  }

  @usableFromInline
  internal var _core: _Core

  public var type: TopLevelType {
    get { return self._core._type }
    set { self._core._type = newValue }
  }

  public var tree: Tree? {
    get { return self._core._tree }
    set { self._core._tree = newValue }
  }

  public var subtype: Subtype {
    get { return self._core._subtype }
    set { self._core._subtype = newValue }
  }

  public var suffix: Suffix? {
    get { return self._core._suffix }
    set { self._core._suffix = newValue }
  }

  public var parameters: [ParameterName: String]?

  internal init(core: _Core, parameters: Parameters?) {
    self._core = core
    self.parameters = parameters
  }

  /// Default initializer
  public init(
    type: TopLevelType,
    tree: Tree? = nil,
    subtype: Subtype,
    suffix: Suffix? = nil,
    parameters: [ParameterName: String]? = nil
  ) {
    self.init(
      core: _Core(type: type, tree: tree, subtype: subtype, suffix: suffix),
      parameters: parameters
    )
  }
}

extension MIMEType {
  fileprivate static func _convertParameters(_ stringParameters: [String: String]) -> Parameters? {
    var parameterPairs: [(key: ParameterName, value: String)] = []
    for (stringKey, stringValue) in stringParameters {
      guard let name = ParameterName(stringKey) else {
        return nil
      }
      parameterPairs.append((name, stringValue))
    }
    return Parameters(uniqueKeysWithValues: parameterPairs)
  }

  @available(*, deprecated)
  public init?(type:TopLevelType,
               tree:Tree?,
               subtype subtypeString: String,
               suffix:Suffix?,
               parameters:[String:String]?) {
    guard let subtype = Subtype(_validating: subtypeString) else {
      return nil
    }

    let core = _Core(type: type, tree: tree, subtype: subtype, suffix: suffix)
    if let stringParamters = parameters {
      guard let params = MIMEType._convertParameters(stringParamters) else {
        return nil
      }
      self.init(core: core, parameters: params)
    } else {
      self.init(core: core, parameters: nil)
    }
  }
}

extension MIMEType: Equatable, Hashable {
  @inlinable
  internal func _isEqual(to other: MIMEType, ignoreCaseOfParameterValues: Bool) -> Bool {
    guard self._core == other._core else {
      return false
    }

    switch (self.parameters, other.parameters) {
    case (nil, nil):
      return true
    case (nil, let otherParameters?):
      return otherParameters.isEmpty
    case (let myParameters?, nil):
      return myParameters.isEmpty
    case (let myParameters?, let otherParameters?):
      if !ignoreCaseOfParameterValues {
        return myParameters == otherParameters
      }

      guard myParameters.count == otherParameters.count else {
        return false
      }
      for (name, myValue) in myParameters {
        guard let otherValue = otherParameters[name],
              myValue.isASCIICaseInsensitivelyEqual(to: otherValue) else {
          return false
        }
      }
      return true
    }
  }

  @inlinable
  public static func ==(lhs:MIMEType, rhs:MIMEType) -> Bool {
    return lhs._isEqual(to: rhs, ignoreCaseOfParameterValues: false)
  }
  
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self._core)
    hasher.combine(self.parameters)
  }
}

/// A parser to parse media type such as "application/xhtml+xml; charset=UTF-8".
public struct MIMETypeParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = MIMEType

  let input: Input
  let utf8: Input.UTF8View
  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: MIMEType, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    guard let topLevelTypeString = MIMEType.TopLevelTypeString.Parser<Input.SubSequence>.parse(
      input,
      from: &currentIndex
    ) else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isSlash) else {
      return nil
    }

    guard let treeSubtypeSuffixStringResult = _MIMETypeRestrictedNameParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex
    ) else {
      return nil
    }

    let topLevelType = MIMEType.TopLevelType(string: topLevelTypeString)
    let tree: MIMEType.Tree? = treeSubtypeSuffixStringResult.indexOfFirstPeriod.map {
      let treeString = MIMEType.TreeString(
        _validatedString: treeSubtypeSuffixStringResult.name[..<$0]
      )
      return MIMEType.Tree(string: treeString)
    }
    let subtype: MIMEType.Subtype = ({ () -> MIMEType.Subtype in
      let wholeString = treeSubtypeSuffixStringResult.name
      let indexOfFirstPeriod = treeSubtypeSuffixStringResult.indexOfFirstPeriod
      let indexOfLastPlusSign = treeSubtypeSuffixStringResult.indexOfLastPlusSign
      switch (indexOfFirstPeriod, indexOfLastPlusSign) {
      case (nil, nil):
        return MIMEType.Subtype(_validatedString: wholeString)
      case (nil, let plusIndex?):
        return MIMEType.Subtype(_validatedString: wholeString[..<plusIndex])
      case (let periodIndex?, nil):
        return MIMEType.Subtype(_validatedString: wholeString[periodIndex<..])
      case (let periodIndex?, let plusIndex?):
        return MIMEType.Subtype(_validatedString: wholeString[periodIndex<..<plusIndex])
      }
    })()
    let suffix: MIMEType.Suffix? = treeSubtypeSuffixStringResult.indexOfLastPlusSign.map {
      let suffixString = MIMEType.SuffixString(
        _validatedString: treeSubtypeSuffixStringResult.name[$0<..]
      )
      return MIMEType.Suffix(string: suffixString)
    }
    let core = MIMEType._Core(type: topLevelType, tree: tree, subtype: subtype, suffix: suffix)

    func __parseNextParameter() -> (name: MIMEType.ParameterName, value: String)? {
      guard let _ = _SemicolonSeparatorParser<Input.SubSequence>.parse(
        input,
        from: &currentIndex
      ) else {
        return nil
      }

      var tmpCurrentIndex = currentIndex
      guard let nameResult = _MIMETypeRestrictedNameParser<Input.SubSequence>.parse(
        input,
        from: &tmpCurrentIndex
      ) else {
        return nil
      }
      guard let _ = self.readCurrentCodeUnit(
        at: &tmpCurrentIndex,
        ifAllowedCodeUnit: \._isEqualSign
      ) else {
        return nil
      }

      var name: MIMEType.ParameterName { MIMEType.ParameterName(_validatedString: nameResult.name) }

      guard tmpCurrentIndex < input.endIndex else {
        currentIndex = tmpCurrentIndex
        return (name: name, value: "")
      }
      if utf8[tmpCurrentIndex]._isDoubleQuotationMark {
        guard let quotedString = QuotedStringParser<Input.SubSequence>.parse(
          input,
          from: &tmpCurrentIndex
        ) else {
          return nil
        }
        currentIndex = tmpCurrentIndex
        return (name: name, value: quotedString.content)
      } else {
        guard let value = self.parseString(
          from: &tmpCurrentIndex,
          while: \._isAvailableInMIMETypeToken
        ) else {
          currentIndex = tmpCurrentIndex
          return (name: name, value: "")
        }
        currentIndex = tmpCurrentIndex
        return (name: name, value: value._string)
      }
    } // func __parseNextParameter

    guard let firstParameter = __parseNextParameter() else {
      return (
        output: MIMEType(core: core, parameters: nil),
        endIndex: currentIndex
      )
    }

    var parameters: MIMEType.Parameters = [firstParameter.name: firstParameter.value]
    while let parameter = __parseNextParameter() {
      parameters[parameter.name] = parameter.value
    }
    return (
      output: MIMEType(core: core, parameters: parameters),
      endIndex: currentIndex
    )
  }
}

extension MIMEType: _InitializableWithParser {
  /// Initialize with `string` such as "application/xhtml+xml; charset=UTF-8"
  ///
  /// - parameter string: must be `type "/" [tree "."] subtype ["+" suffix] *[";" parameter]`
  public init?<S>(_ string: S) where S: StringProtocol {
    self.init(string, parser: MIMETypeParser<S>.self)
  }
}

extension MIMEType {
  /// Returns a set of possible path extensions for the MIME Type represented by the instance.
  public var possiblePathExtensions:Set<MIMEType.PathExtension>? {
    return _mimeType_to_ext[self._core]
  }

  public init?(pathExtension: MIMEType.PathExtension, parameters: [ParameterName: String]? = nil) {
    guard let core = _ext_to_mimeType[pathExtension] else { return nil }
    self.init(core: core, parameters: parameters)
  }

  /// Initialize with a path extension.
  @available(*, deprecated, message: "Use another initializer which takes `[ParameterName: String]` for 'parameters' instead.")
  public init?(pathExtension:MIMEType.PathExtension, parameters:[String:String]?) {
    guard let core = _ext_to_mimeType[pathExtension] else { return nil }
    if let stringParameters = parameters {
      guard let convertedParameters = MIMEType._convertParameters(stringParameters) else {
        return nil
      }
      self.init(core:core, parameters: convertedParameters)
    } else {
      self.init(core: core, parameters: nil)
    }
  }
}

extension MIMEType: CustomStringConvertible {
  @usableFromInline
  internal func _description(sortParameters: Bool) -> String {
    var desc : String = "\(self.type.rawValue)/"
    if let tree = self.tree { desc += "\(tree.rawValue)." }
    desc += self.subtype.description
    if let suffix = self.suffix { desc += "+\(suffix.rawValue)" }

    if let parameters = self.parameters {
      func __appendDescription(name: ParameterName, value: String) {
        desc += "; \(name.description)="
        if value.utf8.allSatisfy(\._isAvailableInMIMETypeToken) {
          desc += value
        } else {
          if let quotedString = value._quotedString {
            desc += quotedString
          } else {
            // FIXME: This may not be the correct way...
            desc += value.addingPercentEncoding(whereAllowedASCIICharacters: \._isAvailableInHTTPToken)!
          }
        }
      }

      if sortParameters {
        for (name, value) in parameters.sorted(by: { $0.key < $1.key }) {
          __appendDescription(name: name, value: value)
        }
      } else {
        for (name, value) in parameters {
          __appendDescription(name: name, value: value)
        }
      }
    }
    return desc
  }

  @inlinable
  public var description: String {
    return _description(sortParameters: false)
  }
}

// MARK: - Related types

/// A string that is available for the value of `boundary` of `multipart/*`.
///
/// - Reference: [RFC 2046 §5.1.1](https://datatracker.ietf.org/doc/html/rfc2046#section-5.1.1)
public struct MultipartBoundary: Sendable,
                                 Equatable,
                                 Hashable,
                                 RawRepresentable,
                                 _InitializableWithParser {
  private struct _Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
    typealias Output = Input.SubSequence

    let input: Input
    let utf8: Input.UTF8View

    init(input: Input) {
      self.input = input
      self.utf8 = input.utf8
    }

    mutating func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
      var currentIndex = self.utf8.startIndex
      var previousIndex = currentIndex
      var count = 0
      var indexOfLastNonSpace: Input.UTF8View.Index? = nil

      while let byte = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isAvailableInMultipartFormDataBoundary
      ) {
        guard count < 70 else {
          break
        }
        if !byte._isSpace {
          indexOfLastNonSpace = previousIndex
        }
        count += 1
        previousIndex = currentIndex
      }

      guard let lastIndex = indexOfLastNonSpace else {
        return nil
      }
      return (input[...lastIndex], utf8.index(after: lastIndex))
    }
  }

  public typealias RawValue = String

  public let rawValue: String

  internal init<S>(_validatedString string: S) where S: StringProtocol {
    self.rawValue = string._string
  }

  public init?<S>(rawValue: S) where S: StringProtocol {
    // Handle `transport-padding CRLF`
    let trimmed = rawValue.dropTrailingHTTPNewlines(maxCount: 1).dropTrailingHTTPWhitespaces()
    guard let validated = _Parser<S.SubSequence.SubSequence>.parse(trimmed)?.output else {
      return nil
    }
    self.init(_validatedString: validated)
  }

  /// Returns the string which is formed by concatenating "`--`", `rawValue`, and `CRLF`.
  @inlinable
  public var startBoundary: String {
    return "--\(rawValue)\u{0D}\u{0A}"
  }

  /// Returns the string which is formed by concatenating `CRLF`, "`--`", `rawValue`, and "`--`".
  @inlinable
  public var endBoundary: String {
    return "\u{0D}\u{0A}--\(rawValue)--"
  }

  /// Creates a new boundary.
  public static func random() -> MultipartBoundary {
    enum __Constants {
      static let alphanumerics: Array<Unicode.UTF8.CodeUnit> = [
        0x30...0x39, 0x41...0x5A, 0x61...0x7A
      ].flatMap(\.self)
      static let suffix = "--SwiftNetworkGear".utf8
    }

    var rawValueData = Data(capacity: 70)
    for _ in 0..<36 {
      rawValueData.append(__Constants.alphanumerics.randomElement()!)
    }
    rawValueData.append(contentsOf: __Constants.suffix)

    return MultipartBoundary(
      _validatedString: String(decoding: rawValueData, as: UTF8.self)
    )
  }
}

// MARK: - Common Mediat Types

extension MIMEType.Subtype {
  public static let css: MIMEType.Subtype = .init(_validatedString: "css")
  public static let html: MIMEType.Subtype = .init(_validatedString: "html")
  public static let javascript: MIMEType.Subtype = .init(_validatedString: "javascript")
  public static let json: MIMEType.Subtype = .init(_validatedString: "json")
  public static let octetStream: MIMEType.Subtype = .init(_validatedString: "octet-stream")
  public static let plain: MIMEType.Subtype = .init(_validatedString: "plain")
  public static let wwwFormURLEncoded: MIMEType.Subtype = .init(_validatedString: "x-www-form-urlencoded")
}

extension MIMEType.ParameterName {
  public static let boundary: MIMEType.ParameterName = .init(_validatedString: "boundary")
  public static let charset: MIMEType.ParameterName = .init(_validatedString: "charset")
}

extension MIMEType {
  @inlinable @discardableResult
  public mutating func removeParameter(forName name: ParameterName) -> String? {
    return self.parameters?.removeValue(forKey: name)
  }

  @inlinable @discardableResult
  public mutating func setParameter(_ value: String, forName name: ParameterName) -> String? {
    if self.parameters.isNil {
      self.parameters = [name: value]
      return nil
    } else {
      return self.parameters!.updateValue(value, forKey: name)
    }
  }

  @inlinable
  public var boundary: MultipartBoundary? {
    get {
      return self.parameters?[.boundary].flatMap { MultipartBoundary(rawValue: $0) }
    }
    set {
      guard let newBoundary = newValue else {
        self.removeParameter(forName: .boundary)
        return
      }
      self.setParameter(newBoundary.rawValue, forName: .boundary)
    }
  }

  @inlinable
  public var charset: String? {
    get {
      return self.parameters?[.charset]
    }
    set {
      guard let newCharset = newValue else {
        self.removeParameter(forName: .charset)
        return
      }
      self.setParameter(newCharset, forName: .charset)
    }
  }
}

extension MIMEType {
  private func _setting(charset: String) -> MIMEType {
    var newType = self
    newType.charset = charset
    return newType
  }

  private func _setting(encoding: String.Encoding) -> MIMEType {
    #if compiler(>=6.3)
    if #available(macOS 26.4, *), let charset = encoding.ianaName {
      return _setting(charset: charset)
    }
    #endif
    guard let charset = encoding.ianaCharacterSetName else {
      return self
    }
    return _setting(charset: charset)
  }

  private static func _image(
    tree: Tree? = nil,
    subtype: String,
    suffix: Suffix? = nil
  ) -> MIMEType {
    return MIMEType(
      type: .image,
      tree: tree,
      subtype: Subtype(_validatedString: subtype),
      suffix: suffix
    )
  }

  /// `image/apng`
  public static let apng: MIMEType = ._image(subtype: "apng")

  /// `image/avif`
  public static let avif: MIMEType = ._image(subtype: "avif")

  /// `text/css`
  public static let css: MIMEType = .init(type: .text, subtype: .css)

  /// `text/css; charset=...`
  public static func css(charset: String) -> MIMEType {
    return .css._setting(charset: charset)
  }

  /// `text/css; charset=...`
  public static func css(encoding: String.Encoding) -> MIMEType {
    return .css._setting(encoding: encoding)
  }

  /// `image/gif`
  public static let gif: MIMEType = ._image(subtype: "gif")

  /// `text/html`
  public static let html: MIMEType = .init(type: .text, subtype: .html)

  /// `text/html; charset=...`
  public static func html(charset: String) -> MIMEType {
    return .html._setting(charset: charset)
  }

  /// `text/html; charset=...`
  public static func html(encoding: String.Encoding) -> MIMEType {
    return .html._setting(encoding: encoding)
  }

  /// `text/javascript`
  public static let javascript: MIMEType = .init(type: .text, subtype: .javascript)

  /// `text/javascript; charset=...`
  public static func javascript(charset: String) -> MIMEType {
    return .javascript._setting(charset: charset)
  }

  /// `text/javascript; charset=...`
  public static func javascript(encoding: String.Encoding) -> MIMEType {
    return .javascript._setting(encoding: encoding)
  }

  /// `image/jpeg`
  public static let jpeg: MIMEType = ._image(subtype: "jpeg")

  /// `application/json`
  public static let json: MIMEType = .init(type: .application, subtype: .json)

  /// `application/json; charset=...`
  public static func json(charset: String) -> MIMEType {
    return .json._setting(charset: charset)
  }

  /// `application/json; charset=...`
  public static func json(encoding: String.Encoding) -> MIMEType {
    return .json._setting(encoding: encoding)
  }

  /// `multipart/byteranges; boundary=...`
  public static func multipartByteRanges(boundary: MultipartBoundary) -> MIMEType {
    return MIMEType(
      type: .multipart,
      subtype: Subtype(_validatedString: "byteranges"),
      parameters: [.boundary: boundary.rawValue]
    )
  }

  /// `multipart/form-data; boundary=...`
  public static func multipartFormData(boundary: MultipartBoundary) -> MIMEType {
    return MIMEType(
      type: .multipart,
      subtype: Subtype(_validatedString: "form-data"),
      parameters: [.boundary: boundary.rawValue]
    )
  }

  /// `application/octet-stream`
  public static let octetStream: MIMEType = .init(type: .application, subtype: .octetStream)

  /// `text/plain`
  public static let plainText: MIMEType = .init(type: .text, subtype: .plain)

  /// `text/plain; charset=...`
  public static func plainText(charset: String) -> MIMEType {
    return .plainText._setting(charset: charset)
  }

  /// `text/plain; charset=...`
  public static func plainText(encoding: String.Encoding) -> MIMEType {
    return .plainText._setting(encoding: encoding)
  }

  /// `image/png`
  public static let png: MIMEType = ._image(subtype: "png")

  /// `image/svg+xml`
  public static let svg: MIMEType = ._image(subtype: "svg", suffix: .xml)

  /// `image/webp`
  public static let webp: MIMEType = ._image(subtype: "webp")

  /// `application/x-www-form-urlencoded`
  public static let wwwFormURLEncoded: MIMEType = .init(type: .application, subtype: .wwwFormURLEncoded)
}
