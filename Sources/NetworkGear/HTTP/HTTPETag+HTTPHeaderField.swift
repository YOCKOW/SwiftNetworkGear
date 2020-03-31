/* *************************************************************************************************
 HTTPETag+HeaderField.swift
   © 2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
extension HTTPETag: HTTPHeaderFieldValueConvertible {
  public init?(headerFieldValue: HTTPHeaderFieldValue) {
    self.init(headerFieldValue.rawValue)
  }
  
  public var headerFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.description)!
  }
}

/// Generates a header field whose name is "ETag"
public struct HTTPETagHeaderFieldDelegate: HTTPHeaderFieldDelegate {
  public typealias ValueSource = HTTPETag
  
  public static var name: HTTPHeaderFieldName { return .eTag }
  
  public static var type: HTTPHeaderField.PresenceType { return .single }
  
  public var source: HTTPETag
  
  public init(_ source: HTTPETag) {
    self.source = source
  }
}

