/* *************************************************************************************************
 ETag.swift
   © 2017-2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import yExtensions

/// A type that represents the content of `opaque-tag` defined in
/// [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#section-8.8.3).
@dynamicMemberLookup
public struct HTTPOpaqueTagContentString: Sendable, Equatable, Hashable {
  private let _string: String

  fileprivate init<S>(_alreadyValidatedString string: S) where S: StringProtocol {
    self._string = string._string
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<String, T>) -> T {
    return self._string[keyPath: dynamicMember]
  }
}

extension HTTPOpaqueTagContentString: Sequence {
  public typealias Iterator = String.Iterator
  public typealias Element = String.Element
  public func makeIterator() -> String.Iterator { return self._string.makeIterator() }
}

extension HTTPOpaqueTagContentString: Collection, BidirectionalCollection {
  public typealias Index = String.Index
  public var startIndex: String.Index { self._string.startIndex }
  public var endIndex: String.Index { self._string.endIndex }
  public subscript(position: String.Index) -> String.Element { self._string[position] }
  public func index(after ii: String.Index) -> String.Index { self._string.index(after: ii) }
  public func index(before ii: String.Index) -> String.Index { self._string.index(before: ii) }
}

extension HTTPOpaqueTagContentString: CustomStringConvertible {
  public var description: String { self._string }
}

public struct HTTPOpaqueTagContentParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = HTTPOpaqueTagContentString

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: HTTPOpaqueTagContentString, endIndex: Input.Index)? {
    if utf8.isEmpty {
      return (HTTPOpaqueTagContentString(_alreadyValidatedString: ""), input.startIndex)
    }

    let startsWithDoubleQuotationMark = utf8.first!._isDoubleQuotationMark
    var currentIndex = (
      startsWithDoubleQuotationMark ? utf8.index(after: utf8.startIndex)
      : utf8.startIndex
    )

    let content = self.parseString(from: &currentIndex, while: \._isAvailableInHTTPOpaqueTagContent) ?? ""
    if startsWithDoubleQuotationMark {
      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isDoubleQuotationMark
      ) else {
        return nil
      }
    }
    return (HTTPOpaqueTagContentString(_alreadyValidatedString: content), currentIndex)
  }
}

extension HTTPOpaqueTagContentString: _InitializableWithParser {
  public init?<S>(validating string: S) where S: StringProtocol {
    self.init(string, parser: HTTPOpaqueTagContentParser<S>.self)
  }
}

extension HTTPOpaqueTagContentString: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType

  public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

  public init(stringLiteral value: String) {
    guard let content = HTTPOpaqueTagContentString(validating: value) else {
      fatalError("Invalid value for `opaque-tag`!")
    }
    self = content
  }
}

/// Represents a value of [ETag](https://datatracker.ietf.org/doc/html/rfc9110#section-8.8.3).
public enum HTTPETag: Sendable {
  /// Weak entity tag.
  case weak(HTTPOpaqueTagContentString)

  /// Strong entity tag.
  case strong(HTTPOpaqueTagContentString)

  /// Represents `*`, which is used in `If-Match` or `If-None-Match` header field.
  case any
}

extension HTTPETag {
  /// Initialize from `string`
  /// e.g.) "foo", W/"bar"
  public init?(_ string: String) {
    if string == "*" {
      self = .any
      return
    }

    if string.hasPrefix(#"W/""#) {
      let startIndex = string.index(string.startIndex, offsetBy: 2)
      guard let content = HTTPOpaqueTagContentString(validating: string[startIndex...]) else {
        return nil
      }
      self = .weak(content)
    } else if string.hasPrefix(#"""#) {
      guard let content = HTTPOpaqueTagContentString(validating: string) else {
        return nil
      }
      self = .strong(content)
    } else {
      return nil
    }
  }
}

extension HTTPETag: CustomStringConvertible {
  public var description: String {
    // NOTE: ETag should be no longer escaped.
    //       See https://datatracker.ietf.org/doc/html/rfc9110#section-8.8.3-3.1
    switch self {
    case .weak(let tag):
      return #"W/"\#(tag)""#
    case .strong(let tag):
      return #""\#(tag)""#
    case .any:
      return "*"
    }
  }
}

extension HTTPETag: Equatable {
  public static func ==(lhs:HTTPETag, rhs:HTTPETag) -> Bool {
    switch (lhs, rhs) {
    case (.weak(let lstr), .weak(let rstr)) where lstr == rstr: return true
    case (.strong(let lstr), .strong(let rstr)) where lstr == rstr: return true
    case (.any, .any): return true
    default: return false
    }
  }
}

extension HTTPETag: Hashable {
  public func hash(into hasher:inout Hasher) {
    switch self {
    case .weak(let tag): hasher.combine("weak:" + tag)
    case .strong(let tag): return hasher.combine(tag)
    case .any: hasher.combine("*")
    }
  }
}

infix operator =~: ComparisonPrecedence
extension HTTPETag {
  public static func =~(lhs:HTTPETag, rhs:HTTPETag) -> Bool {
    if lhs == rhs { return true }
    switch (lhs, rhs) {
    case (.weak(let lstr), .strong(let rstr)) where lstr == rstr: return true
    case (.strong(let lstr), .weak(let rstr)) where lstr == rstr: return true
    default: return false
    }
  }
}

extension Sequence where Element == HTTPETag {
  public func contains(_ tag:HTTPETag, weakComparison:Bool = false) -> Bool {
    let predicate:(HTTPETag) -> Bool = weakComparison ? { $0 =~ tag } : { $0 == tag }
    return self.contains(where:predicate)
  }
}

