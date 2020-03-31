/* *************************************************************************************************
 HTTPETag+HeaderField.swift
   © 2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
extension HTTPETag: HTTPHeaderFieldValueConvertible {
  public init?(_ value: HTTPHeaderFieldValue) {
    self.init(value.rawValue)
  }
  
  public var httpHeaderFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.description)!
  }
}

/// Generates a header field whose name is "ETag"
public struct HTTPETagHeaderFieldDelegate: HTTPHeaderFieldDelegate {
  public typealias HTTPHeaderFieldValueSource = HTTPETag
  
  public static var name: HTTPHeaderFieldName { return .eTag }
  
  public static var type: HTTPHeaderField.PresenceType { return .single }
  
  public var source: HTTPETag
  
  public init(_ source: HTTPETag) {
    self.source = source
  }
}

