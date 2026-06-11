/* *************************************************************************************************
 ContentTransferEncoding.swift
   © 2017-2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Represents "Content-Transfer-Encoding".
/// It may not be used directly.
public enum ContentTransferEncoding: String, RawRepresentable, Sendable {
  case `7bit` = "7bit"

  @available(*, deprecated)
  public static let _7bit: ContentTransferEncoding = .`7bit`

  case `8bit` = "8bit"

  @available(*, deprecated)
  public static let _8bit: ContentTransferEncoding = .`8bit`

  case base64 = "base64"

  case binary = "binary"

  case quotedPrintable = "quoted-printable"

  @inlinable
  public init?<S>(rawValue: S) where S: StringProtocol {
    switch rawValue._caseInsensitive {
    case "7bit": self = .`7bit`
    case "8bit": self = .`8bit`
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
