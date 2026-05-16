/* *************************************************************************************************
 ASCIICaseInsensitiveString.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import yExtensions

/// A string that is always compared to another string with
/// [ASCII case-insensitive match](https://infra.spec.whatwg.org/#ascii-case-insensitive).
@dynamicMemberLookup
public struct ASCIICaseInsensitiveString: Sendable, LosslessStringConvertible {
  private var _string: String

  public var description: String { _string }

  public init(_ string: String) {
    self._string = string
  }

  public init(_ token: HTTPTokenString) {
    self._string = token._string
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<String, T>) -> T {
    return _string[keyPath: dynamicMember]
  }
}

extension ASCIICaseInsensitiveString: Equatable {
  public static func ==(lhs: ASCIICaseInsensitiveString, rhs: ASCIICaseInsensitiveString) -> Bool {
    return lhs._string.isASCIICaseInsensitivelyEqual(to: rhs._string)
  }
}

extension ASCIICaseInsensitiveString: Hashable {
  public func hash(into hasher: inout Hasher) {
    for byte in _string.utf8 {
      if 0x61 <= byte && byte <= 0x7A {
        hasher.combine(byte - 0x20)
      } else {
        hasher.combine(byte)
      }
    }
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
