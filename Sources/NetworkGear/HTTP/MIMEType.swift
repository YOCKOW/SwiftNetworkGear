/* *************************************************************************************************
 MIMEType.swift
   © 2017-2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
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

    public static let octetStream: Subtype = Subtype(_validatedString: "octet-stream")
  }

  public enum Suffix: String, Comparable, Sendable {
    case xml
    case json
    case ber
    case der
    case fastinfoset
    case wbxml
    case zip
    case cbor
    
    public static func <(lhs: Suffix, rhs: Suffix) -> Bool {
      return lhs.rawValue < rhs.rawValue
    }
  }
  
  public typealias Parameters = Dictionary<String, String>
  
  /// Holds properties of `MIMEType` except parameters.
  internal struct _Core: Hashable, Sendable {
    internal var _type: TopLevelType
    
    internal var _tree: Tree?

    internal var _subtype: Subtype
    
    internal var _suffix: Suffix?
    
    internal init(type:TopLevelType, tree:Tree?, subtype:Subtype, suffix:Suffix?) {
      self._type = type
      self._tree = tree
      self._subtype = subtype
      self._suffix = suffix
    }
    
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
  
  internal var _parameters: Parameters?
  public var parameters: [String:String]? {
    get {
      return self._parameters
    }
    set {
      if let newParameters = newValue {
        for key in newParameters.keys {
          guard key.utf8.allSatisfy(\._isAvailableInMIMETypeToken) else {
            fatalError("Invalid key exists.")
          }
        }
      }
      self._parameters = newValue
    }
  }
  
  internal init?(core:_Core, parameters:Parameters?) {
    self._core = core
    self.parameters = parameters
  }

  /// Default initializer
  @available(*, deprecated)
  public init?(type:TopLevelType,
               tree:Tree? = nil,
               subtype subtypeString: String,
               suffix:Suffix? = nil,
               parameters:[String:String]? = nil) {
    guard let subtype = Subtype(_validating: subtypeString) else {
      return nil
    }
    self.init(core:_Core(type:type, tree:tree, subtype:subtype, suffix:suffix),
              parameters:parameters)
  }
}

extension MIMEType: Hashable {
  public static func ==(lhs:MIMEType, rhs:MIMEType) -> Bool {
    return lhs._core == rhs._core && lhs._parameters == rhs._parameters
  }
  
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self._core)
    hasher.combine(self._parameters)
  }
}

extension MIMEType {
  /// Initialize with `string` such as "application/xhtml+xml; charset=UTF-8"
  ///
  /// - parameter string: must be `type "/" [tree "."] subtype ["+" suffix] *[";" parameter]`
  public init?<S>(_ string: S) where S: StringProtocol {
    let (type_s, tree_subtype_suffix_parameters_s_nilable) = string.splitOnce(separator:"/")
    
    guard let type = TopLevelType(rawValue:type_s.lowercased()) else { return nil }
    
    guard let tree_subtype_suffix_parameters_s = tree_subtype_suffix_parameters_s_nilable else {
      return nil
    }
    
    let (tree, subtype_suffix_parameters_s): (Tree?, S.SubSequence) = ({
      if let indexOfFirstDot = $0.firstIndex(of:".") {
        let tree_s = $0[$0.startIndex..<indexOfFirstDot]
        if let tree = Tree(rawValue:String(tree_s)) {
          return (tree, $0[$0.index(after:indexOfFirstDot)..<$0.endIndex])
        }
      }
      return (nil, $0)
    })(tree_subtype_suffix_parameters_s)
    
    let (subtype_suffix_s, parameters_s) = subtype_suffix_parameters_s.splitOnce(separator:";")
    
    let (subtype, suffix): (S.SubSequence, Suffix?) = ({
      if let indexOfLastPlus = $0.lastIndex(of:"+") {
        let suffix_s = $0[$0.index(after:indexOfLastPlus)..<$0.endIndex]
        if let suffix = Suffix(rawValue:String(suffix_s)) {
          return ($0[$0.startIndex..<indexOfLastPlus], suffix)
        }
      }
      return ($0, nil)
    })(subtype_suffix_s)
    
    let parameters:[String:String]? = parameters_s != nil ? Dictionary<String,String>(parsing:String(parameters_s!)) : nil
    
    self.init(type:type,
              tree:tree,
              subtype:String(subtype),
              suffix:suffix,
              parameters:parameters)
  }
}

extension MIMEType {
  /// Returns a set of possible path extensions for the MIME Type represented by the instance.
  public var possiblePathExtensions:Set<MIMEType.PathExtension>? {
    return _mimeType_to_ext[self._core]
  }
  
  /// Initialize with a path extension.
  public init?(pathExtension:MIMEType.PathExtension, parameters:[String:String]? = nil) {
    guard let core = _ext_to_mimeType[pathExtension] else { return nil }
    self.init(core:core, parameters:parameters)
  }
}

extension MIMEType: CustomStringConvertible {
  public var description: String {
    var desc : String = "\(self.type.rawValue)/"
    if let tree = self.tree { desc += "\(tree.rawValue)." }
    desc += self.subtype.description
    if let suffix = self.suffix { desc += "+\(suffix.rawValue)" }
    
    if let parameters = self.parameters {
      for (key, value) in parameters {
        desc += "; \(key)="
        if value.utf8.allSatisfy(\._isAvailableInMIMETypeToken) {
          desc += value
        } else {
          let escapedValue = value.replacingOccurrences(of:"\\", with:"\\\\").replacingOccurrences(of:"\"", with:"\\\"")
          desc += "\"\(escapedValue)\""
        }
      }
    }
    return desc
  }
}

extension MIMEType {
  public static let wwwFormURLEncoded: MIMEType = .init(type: .application, subtype: "x-www-form-urlencoded")!
}
