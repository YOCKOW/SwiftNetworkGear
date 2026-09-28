/* *************************************************************************************************
 MIMEType+HTTPHeaderField.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
extension MIMEType: HTTPHeaderFieldValueConvertible {
  public init?(_ value: HTTPHeaderFieldValue) {
    self.init(value.rawValue)
  }
  
  public var httpHeaderFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.description)!
  }
}

/// Generates a header field whose name is "Content-Type"
public struct MIMETypeHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate {
  public typealias HTTPHeaderFieldValueSource = MIMEType
  
  public static var name: HTTPHeaderFieldName { return .contentType }
  
  public static var type: HTTPHeaderField.PresenceType { return .single }
  
  public var source: MIMEType
  
  public init(_ source: MIMEType) {
    self.source = source
  }
}

public typealias ContentTypeHTTPHeaderFieldDelegate = MIMETypeHTTPHeaderFieldDelegate
