/* *************************************************************************************************
 ContentLengthHTTPHeaderFieldDelegate.swift
   © 2018,2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
/// Generates "Content-Length".
public struct ContentLengthHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate, Sendable {
  public typealias HTTPHeaderFieldValueSource = UInt
  
  public static var name: HTTPHeaderFieldName { return .contentLength }
  public static var type: HTTPHeaderField.PresenceType { return .single }
  
  public var source: UInt
  
  public init(_ source: UInt) {
    self.source = source
  }
}
