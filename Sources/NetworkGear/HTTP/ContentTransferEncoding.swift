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
    let caseInsensitive = rawValue._caseInsensitive
    func __is(_ string: String) -> Bool { caseInsensitive._isEqual(to: string) }

    if __is("7bit") { self = .`7bit` }
    else if __is("8bit") { self = .`8bit` }
    else if __is("base64") { self = .base64 }
    else if __is("binary") { self = .binary }
    else if __is("quoted-printable") { self = .quotedPrintable }
    else { return nil }
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
