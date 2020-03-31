/* *************************************************************************************************
 ContentDispositionHTTPHeaderField.swift
   © 2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
extension ContentDisposition: HTTPHeaderFieldValueConvertible {
  public init?(_ value: HTTPHeaderFieldValue) {
    self.init(value.rawValue)
  }
  
  public var httpHeaderFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.description)!
  }
}

/// Represents "Content-Disposition:"
public struct ContentDispositionHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate {
  public typealias HTTPHeaderFieldValueSource = ContentDisposition
  
  public static let name: HTTPHeaderFieldName = .contentDisposition
  public static let type: HTTPHeaderField.PresenceType = .single
  
  public var source: ContentDisposition
  
  public init(_ source: ContentDisposition) {
    self.source = source
  }
}
