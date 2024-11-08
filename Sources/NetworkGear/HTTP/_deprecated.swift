/* *************************************************************************************************
 _deprecated.swift
   © 2023,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// Here are deprecated constants in response to autogenerating.

@available(*, deprecated, message: "Deprecated with update in Sep. 2023.")
extension HTTPHeaderFieldName {
  public static let contentTransferEncoding = HTTPHeaderFieldName(rawValue: "Content-Transfer-Encoding")!
  public static let cost = HTTPHeaderFieldName(rawValue: "Cost")!
  public static let messageID = HTTPHeaderFieldName(rawValue: "Message-ID")!
  public static let title = HTTPHeaderFieldName(rawValue: "Title")!
  public static let version = HTTPHeaderFieldName(rawValue: "Version")!
  public static let xDeviceAccept = HTTPHeaderFieldName(rawValue: "X-Device-Accept")!
  public static let xDeviceAcceptCharset = HTTPHeaderFieldName(rawValue: "X-Device-Accept-Charset")!
  public static let xDeviceAcceptEncoding = HTTPHeaderFieldName(rawValue: "X-Device-Accept-Encoding")!
  public static let xDeviceAcceptLanguage = HTTPHeaderFieldName(rawValue: "X-Device-Accept-Language")!
  public static let xDeviceUserAgent = HTTPHeaderFieldName(rawValue: "X-Device-User-Agent")!
}
