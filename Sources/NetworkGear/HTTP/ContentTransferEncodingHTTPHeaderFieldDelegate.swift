/* *************************************************************************************************
 ContentTransferEncodingHTTPHeaderFieldDelegate.swift
   © 2018,2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Generate the value of "Content-Transfer-Encoding:"
public struct ContentTransferEncodingHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate, Sendable {
  public typealias HTTPHeaderFieldValueSource = ContentTransferEncoding
  
  public static var name: HTTPHeaderFieldName { return .contentTransferEncoding }
  public static var type: HTTPHeaderField.PresenceType { return .single }
  
  public var source: ContentTransferEncoding
  
  public init(_ source: ContentTransferEncoding) {
    self.source = source
  }
}
