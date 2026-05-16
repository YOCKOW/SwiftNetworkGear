/* *************************************************************************************************
 MIMECharsetNameString.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

/// A string that represents the name of a "IANA Charset".
public struct MIMECharsetNameString: Sendable {
  public let name: String

  @inlinable
  internal init(name: String) {
    assert(!name.isEmpty)
    self.name = name
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
    #if compiler(>=6.3)
    if #available(macOS 26.4, *) {
      if let encoding = String.Encoding(ianaName: self.name) {
        return encoding
      }
    }
    #endif
    return String.Encoding(ianaCharacterSetName: self.name)
  }

  public init?(encoding: String.Encoding) {
    guard let name = ({
      #if compiler(>=6.3)
      if #available(macOS 26.4, *) {
        if let name = encoding.ianaName {
          return name
        }
      }
      #endif
      return encoding.ianaCharacterSetName
    })() else {
      return nil
    }
    self.init(name: name, isUsedInExtendedParameterValue: true)
  }
}
