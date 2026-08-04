/* *************************************************************************************************
 HTTPTokenString.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import Ranges
import yExtensions

@usableFromInline
internal protocol HTTPTokenStringProtocol: Sendable,
                                           Equatable,
                                           Hashable,
                                           Sequence,
                                           Collection,
                                           BidirectionalCollection,
                                           CustomStringConvertible,
                                           ExpressibleByStringLiteral
where Self.StringRepresentation: StringProtocol,
      Self.StringRepresentation: _BidirectionalUTF8ViewAvailableStringProtocol,
      Self.Iterator == Self.StringRepresentation.Iterator,
      Self.Element == Self.StringRepresentation.Element,
      Self.Index == Self.StringRepresentation.Index,
      Self.SubSequence: HTTPTokenStringProtocol {
  associatedtype StringRepresentation
  var _string: StringRepresentation { get }
  init<S>(_alreadyValidatedString: S) where S: StringProtocol
}

extension HTTPTokenStringProtocol {
  @inlinable
  init?<S>(_validating string: S) where S: StringProtocol {
    guard !string.isEmpty && string.utf8.allSatisfy(\._isAvailableInHTTPToken) else {
      return nil
    }
    self.init(_alreadyValidatedString: string)
  }

  @inlinable
  func _isEqual<T>(to other: T) -> Bool where T: HTTPTokenStringProtocol {
    return self._string == other._string
  }

  @inlinable
  func _appending<T>(_ other: T) -> HTTPTokenString where T: HTTPTokenStringProtocol {
    return HTTPTokenString(_alreadyValidatedString: self._string.appending(other._string))
  }

  @inlinable
  func _subsequence<R>(in bounds: R) -> SubSequence where R: GeneralizedRange, R.Bound == Self.Index {
    return SubSequence(_alreadyValidatedString: self._string[bounds])
  }

  @inlinable
  var _utf8: StringRepresentation.BidirectionalUTF8View {
    self._string.utf8
  }
}

/// A type that represents `token` defined in
/// [RFC 9110 §5.6.2](https://datatracker.ietf.org/doc/html/rfc9110#section-5.6.2).
@dynamicMemberLookup
public struct HTTPTokenString: HTTPTokenStringProtocol {
  @usableFromInline
  internal let _string: String

  @inlinable
  internal init<S>(_alreadyValidatedString string: S) where S: StringProtocol {
    self._string = string._string
  }

  @inlinable
  public init?<S>(validating string: S) where S: StringProtocol {
    self.init(_validating: string)
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<String, T>) -> T {
    return self._string[keyPath: dynamicMember]
  }

  @inlinable
  public func isASCIICaseInsensitivelyEqual<S>(to string: S) -> Bool where S: StringProtocol {
    return _string.isASCIICaseInsensitivelyEqual(to: string)
  }

  @inlinable
  public func appending(_ other: HTTPTokenString) -> HTTPTokenString {
    return self._appending(other)
  }

  @inlinable
  public func appending(_ other: HTTPTokenSubstring) -> HTTPTokenString {
    return self._appending(other)
  }

  public typealias Iterator = String.Iterator
  public typealias Element = String.Element
  public func makeIterator() -> String.Iterator { return self._string.makeIterator() }

  public typealias Index = String.Index
  public var startIndex: Index { self._string.startIndex }
  public var endIndex: Index { self._string.endIndex }
  public subscript(position: Index) -> Element { self._string[position] }
  public func index(after ii: Index) -> Index { self._string.index(after: ii) }
  public func index(before ii: Index) -> Index { self._string.index(before: ii) }

  public typealias SubSequence = HTTPTokenSubstring
  @inlinable public subscript(bounds: Range<Index>) -> HTTPTokenSubstring {
    return self._subsequence(in: bounds)
  }
  @inlinable public subscript<R>(bounds: R) -> HTTPTokenSubstring  where R: GeneralizedRange, R.Bound == Index {
    return self._subsequence(in: bounds)
  }

  public var description: String { self._string }

  public typealias StringLiteralType = String
  public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType
  public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType
  public init(stringLiteral value: String) {
    guard let tokenString = HTTPTokenString(validating: value) else {
      fatalError("Invalid value for `token`?!")
    }
    self = tokenString
  }
}

public struct HTTPTokenSubstring: HTTPTokenStringProtocol {
  @usableFromInline
  internal let _string: Substring

  @inlinable
  internal init<S>(_alreadyValidatedString string: S) where S: StringProtocol {
    self._string = string._substring
  }

  @inlinable
  public init?<S>(validating string: S) where S: StringProtocol {
    self.init(_validating: string)
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<Substring, T>) -> T {
    return self._string[keyPath: dynamicMember]
  }

  @inlinable
  public func isASCIICaseInsensitivelyEqual<S>(to string: S) -> Bool where S: StringProtocol {
    return _string.isASCIICaseInsensitivelyEqual(to: string)
  }

  @inlinable
  public func appending(_ other: HTTPTokenString) -> HTTPTokenString {
    return self._appending(other)
  }

  @inlinable
  public func appending(_ other: HTTPTokenSubstring) -> HTTPTokenString {
    return self._appending(other)
  }

  public typealias Iterator = Substring.Iterator
  public typealias Element = Substring.Element
  public func makeIterator() -> Iterator { return self._string.makeIterator() }

  public typealias Index = Substring.Index
  public var startIndex: Index { self._string.startIndex }
  public var endIndex: Index { self._string.endIndex }
  public subscript(position: Index) -> Element { self._string[position] }
  public func index(after ii: Index) -> Index { self._string.index(after: ii) }
  public func index(before ii: Index) -> Index { self._string.index(before: ii) }

  public typealias SubSequence = HTTPTokenSubstring
  @inlinable public subscript(bounds: Range<Index>) -> HTTPTokenSubstring {
    return self._subsequence(in: bounds)
  }
  @inlinable public subscript<R>(bounds: R) -> HTTPTokenSubstring  where R: GeneralizedRange, R.Bound == Index {
    return self._subsequence(in: bounds)
  }

  public var description: String { self._string._string }

  public typealias StringLiteralType = Substring.StringLiteralType
  public typealias ExtendedGraphemeClusterLiteralType = Substring.ExtendedGraphemeClusterLiteralType
  public typealias UnicodeScalarLiteralType = Substring.UnicodeScalarLiteralType
  public init(stringLiteral value: StringLiteralType) {
    guard let tokenString = HTTPTokenSubstring(validating: value) else {
      fatalError("Invalid value for `token`?!")
    }
    self = tokenString
  }
}

extension FixedWidthInteger {
  /// Creates a new integer value from the given `token` and `radix`.
  @inlinable
  public init?(_ token: HTTPTokenString, radix: Int = 10) {
    self.init(token._string, radix: radix)
  }
}


/// A parser to pull out an HTTP token.
public struct HTTPTokenParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = HTTPTokenString

  internal let input: Input
  internal let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  private var _result: (output: HTTPTokenString, endIndex: Input.Index)? = nil
  private var _parsed: Bool = false
  public mutating func parse() -> (output: HTTPTokenString, endIndex: Input.Index)? {
    if _parsed {
      return _result
    }

    defer {
      _parsed = true
    }

    var index = utf8.startIndex
    guard let rawToken = self.parseString(from: &index, while: \._isAvailableInHTTPToken) else {
      return nil
    }
    _result = (output: HTTPTokenString(_alreadyValidatedString: rawToken), endIndex: index)
    return _result
  }
}
