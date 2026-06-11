/* *************************************************************************************************
 ASCIICaseInsensitiveString.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Ranges
import yExtensions

@usableFromInline
internal protocol ASCIICaseInsensitiveStringProtocol: Equatable,
                                                      Hashable,
                                                      LosslessStringConvertible,
                                                      ExpressibleByStringLiteral {
  associatedtype StringRepresentation: StringProtocol
  var _string: StringRepresentation { get }
  func hasPrefix<S>(_ prefix: S) -> Bool where S: StringProtocol
  func hasPrefix(_ prefix: ASCIICaseInsensitiveString) -> Bool
  func hasPrefix(_ prefix: ASCIICaseInsensitiveSubstring) -> Bool
  subscript<R>(_ range: R) -> ASCIICaseInsensitiveSubstring where R: GeneralizedRange, R.Bound == String.Index { get }
}
extension ASCIICaseInsensitiveStringProtocol {
  @inlinable
  internal func _isEqual<S>(to string: S) -> Bool where S: StringProtocol {
    return self._string.isASCIICaseInsensitivelyEqual(to: string)
  }

  @inlinable
  internal func _isEqual<S>(to other: S) -> Bool where S: ASCIICaseInsensitiveStringProtocol {
    return self._isEqual(to: other._string)
  }

  fileprivate func _hash(into hasher: inout Hasher) {
    for byte in self._string.utf8 {
      if 0x61 <= byte && byte <= 0x7A {
        hasher.combine(byte - 0x20)
      } else {
        hasher.combine(byte)
      }
    }
  }

  @usableFromInline
  internal func _endIndex<S>(ofPrefix prefix: S) -> String.Index? where S: StringProtocol {
    let myUTF8 = _string.utf8
    var myIndex = myUTF8.startIndex
    var prefixIterator = prefix.utf8.makeIterator()
    while let prefixByte = prefixIterator.next() {
      guard myIndex < myUTF8.endIndex else { return nil }
      let myByte = myUTF8[myIndex]
      guard (
        myByte == prefixByte ||
        (0x41 <= myByte && myByte <= 0x5A && myByte + 0x20 == prefixByte) ||
        (0x61 <= myByte && myByte <= 0x7A && myByte - 0x20 == prefixByte)
      ) else {
        return nil
      }
      myUTF8.formIndex(after: &myIndex)
    }
    return myIndex
  }
}

/// A string that is always compared to another string with
/// [ASCII case-insensitive match](https://infra.spec.whatwg.org/#ascii-case-insensitive).
@dynamicMemberLookup
public struct ASCIICaseInsensitiveString: ASCIICaseInsensitiveStringProtocol,
                                          Sendable,
                                          Equatable,
                                          Hashable,
                                          LosslessStringConvertible,
                                          ExpressibleByStringLiteral {
  public typealias StringLiteralType = String.StringLiteralType
  public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType
  public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

  @usableFromInline
  internal private(set) var _string: String

  public static func ==(lhs: ASCIICaseInsensitiveString, rhs: ASCIICaseInsensitiveString) -> Bool {
    return lhs._isEqual(to: rhs)
  }

  public func hash(into hasher: inout Hasher) {
    self._hash(into: &hasher)
  }

  @inlinable
  public var description: String { _string }

  @inlinable
  public init(_ string: String) {
    self._string = string
  }

  @inlinable
  public init(stringLiteral value: String.StringLiteralType) {
    self.init(value)
  }

  @inlinable
  public init(_ token: HTTPTokenString) {
    self._string = token._string
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<String, T>) -> T {
    return _string[keyPath: dynamicMember]
  }

  @inlinable
  public func hasPrefix<S>(_ prefix: S) -> Bool where S: StringProtocol {
    return !self._endIndex(ofPrefix: prefix).isNil
  }

  public func hasPrefix(_ prefix: ASCIICaseInsensitiveString) -> Bool {
    return self.hasPrefix(prefix._string)
  }

  public func hasPrefix(_ prefix: ASCIICaseInsensitiveSubstring) -> Bool {
    return self.hasPrefix(prefix._string)
  }

  @inlinable
  public subscript<R>(_ range: R) -> ASCIICaseInsensitiveSubstring
  where R: GeneralizedRange, R.Bound == String.Index {
    return ASCIICaseInsensitiveSubstring(_string[range])
  }
}


/// A substring that is always compared to another string with
/// [ASCII case-insensitive match](https://infra.spec.whatwg.org/#ascii-case-insensitive).
@dynamicMemberLookup
public struct ASCIICaseInsensitiveSubstring: ASCIICaseInsensitiveStringProtocol,
                                             Sendable,
                                             Equatable,
                                             Hashable,
                                             LosslessStringConvertible,
                                             ExpressibleByStringLiteral {
  public typealias StringLiteralType = Substring.StringLiteralType
  public typealias ExtendedGraphemeClusterLiteralType = Substring.ExtendedGraphemeClusterLiteralType
  public typealias UnicodeScalarLiteralType = Substring.UnicodeScalarLiteralType

  @usableFromInline
  internal private(set) var _string: Substring

  public static func ==(lhs: ASCIICaseInsensitiveSubstring, rhs: ASCIICaseInsensitiveSubstring) -> Bool {
    return lhs._isEqual(to: rhs)
  }

  public func hash(into hasher: inout Hasher) {
    self._hash(into: &hasher)
  }

  @inlinable
  public var description: String { _string._string }

  @inlinable
  public init(_ string: String) {
    self._string = string[...]
  }

  @inlinable
  public init(_ substring: Substring) {
    self._string = substring
  }

  @inlinable
  public init(stringLiteral value: StringLiteralType) {
    self.init(Substring(stringLiteral: value))
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<Substring, T>) -> T {
    return _string[keyPath: dynamicMember]
  }

  @inlinable
  public func hasPrefix<S>(_ prefix: S) -> Bool where S: StringProtocol {
    return !self._endIndex(ofPrefix: prefix).isNil
  }

  public func hasPrefix(_ prefix: ASCIICaseInsensitiveString) -> Bool {
    return self.hasPrefix(prefix._string)
  }

  public func hasPrefix(_ prefix: ASCIICaseInsensitiveSubstring) -> Bool {
    return self.hasPrefix(prefix._string)
  }

  @inlinable
  public subscript<R>(_ range: R) -> ASCIICaseInsensitiveSubstring
  where R: GeneralizedRange, R.Bound == String.Index {
    return ASCIICaseInsensitiveSubstring(_string[range])
  }
}

extension String {
  @inlinable
  internal var _caseInsensitive: ASCIICaseInsensitiveString {
    return ASCIICaseInsensitiveString(self)
  }
}

extension Substring {
  @inlinable
  internal var _caseInsensitive: ASCIICaseInsensitiveSubstring {
    return ASCIICaseInsensitiveSubstring(self)
  }
}

extension StringProtocol {
  @inlinable
  internal var _caseInsensitive: any ASCIICaseInsensitiveStringProtocol {
    if case let string as String = self {
      return string._caseInsensitive
    }
    if case let substring as Substring = self {
      return substring._caseInsensitive
    }
    // Never reach here...
    return ASCIICaseInsensitiveString(String(self))
  }
}


/// A HTTP `token` string that is always compared to another string with
/// [ASCII case-insensitive match](https://infra.spec.whatwg.org/#ascii-case-insensitive).
public struct ASCIICaseInsensitiveHTTPTokenString: Sendable,
                                                   LosslessStringConvertible,
                                                   Equatable,
                                                   Hashable {
  private var _string: ASCIICaseInsensitiveString

  public var description: String { String(describing: _string) }

  public init(_ token: HTTPTokenString) {
    self._string = ASCIICaseInsensitiveString(token._string)
  }

  public init?(_ description: String) {
    guard let token = HTTPTokenString(validating: description) else { return nil }
    self.init(token)
  }

  public static func ==(
    lhs: ASCIICaseInsensitiveHTTPTokenString,
    rhs: ASCIICaseInsensitiveHTTPTokenString
  ) -> Bool {
    return lhs._string == rhs._string
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(_string)
  }
}
