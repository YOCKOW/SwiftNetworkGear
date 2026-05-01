/* *************************************************************************************************
 HTTPMethod+Other.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import yExtensions

/// A type that holds a string that can be valid for an HTTP method.
public struct HTTPMethodString: LosslessStringConvertible, Sendable {
  private let _string: String

  public var description: String { _string }

  public init?(_ description: String) {
    guard description.isLiterallyAcceptableForHTTPMethod else {
      return nil
    }
    self._string = description
  }
}

extension HTTPMethodString: Equatable {
  public static func ==(lhs: HTTPMethodString, rhs: HTTPMethodString) -> Bool {
    return lhs._string.isASCIICaseInsensitivelyEqual(to: rhs._string)
  }
}

extension HTTPMethodString: Hashable {
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

extension HTTPMethod: Hashable {
  public func hash(into hasher: inout Hasher) {
    if case .otherMethod(let string) = self {
      hasher.combine(string)
    } else {
      hasher.combine(self.rawValue)
    }
  }
}
