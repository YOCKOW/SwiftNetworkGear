/* *************************************************************************************************
 HTTPMethod+Other.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import yExtensions

/// A type that holds a string that can be valid for an HTTP method.
public struct HTTPMethodString: LosslessStringConvertible, Sendable, Equatable, Hashable {
  private let _string: ASCIICaseInsensitiveString

  public var description: String { _string.description }

  public init?(_ description: String) {
    guard description.isLiterallyAcceptableForHTTPMethod else {
      return nil
    }
    self._string = ASCIICaseInsensitiveString(description)
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
