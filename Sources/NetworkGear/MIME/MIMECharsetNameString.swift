/* *************************************************************************************************
 MIMECharsetNameString.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

/// A string that represents the name of a "IANA Charset".
public struct MIMECharsetNameString: Sendable, Equatable, Hashable {
  public let name: ASCIICaseInsensitiveString

  @inlinable
  internal init(name: ASCIICaseInsensitiveString) {
    assert(!name.isEmpty)
    self.name = name
  }

  @inlinable
  internal init(name: String) {
    assert(!name.isEmpty)
    self.init(name: ASCIICaseInsensitiveString(name))
  }

  public init?(name: String, isUsedInExtendedParameterValue: Bool) {
    if name.isEmpty {
      return nil
    }
    guard (
      isUsedInExtendedParameterValue &&
      name.utf8.allSatisfy(\._isAvailableInMIMECharsetInExtendedValue)
    ) || (
      name.utf8.allSatisfy(\._isAvailableInMIMECharset)
    ) else {
      return nil
    }
    self.init(name: name)
  }
}

extension MIMECharsetNameString {
  public var encoding: String.Encoding? {
    return String.Encoding(ianaCharsetName: self.name.description)
  }

  public init?(encoding: String.Encoding) {
    guard let name = encoding.ianaCharsetName else {
      return nil
    }
    self.init(name: name, isUsedInExtendedParameterValue: true)
  }
}
