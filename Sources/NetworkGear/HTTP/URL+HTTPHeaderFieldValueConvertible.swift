/* *************************************************************************************************
 URL+HeaderFieldValueConvertible.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

extension URL: HTTPHeaderFieldValueConvertible {
  public init?(headerFieldValue: HTTPHeaderFieldValue) {
    self.init(string:headerFieldValue.rawValue)
  }
  
  public var headerFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.absoluteString)!
  }
}
