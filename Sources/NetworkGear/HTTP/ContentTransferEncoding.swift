/* *************************************************************************************************
 ContentTransferEncoding.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Represents "Content-Transfer-Encoding".
/// It may not be used directly.
public enum ContentTransferEncoding: String, RawRepresentable, Sendable {
  case _7bit = "7bit"
  case _8bit = "8bit"
  case base64 = "base64"
  case binary = "binary"
  case quotedPrintable = "quoted-printable"
  
  public init?(rawValue:String) {
    switch rawValue.lowercased() {
    case "7bit": self = ._7bit
    case "8bit": self = ._8bit
    case "base64": self = .base64
    case "binary": self = .binary
    case "quoted-printable": self = .quotedPrintable
    default: return nil
    }
  }
}

extension ContentTransferEncoding: HTTPHeaderFieldValueConvertible {
  public init?(_ value: HTTPHeaderFieldValue) {
    self.init(rawValue:value.rawValue)
  }
  
  public var httpHeaderFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.rawValue)!
  }
}
