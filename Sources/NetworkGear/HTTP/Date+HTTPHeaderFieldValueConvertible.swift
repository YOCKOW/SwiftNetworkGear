/* *************************************************************************************************
 Date+HeaderFieldValueConvertible.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

extension Date: HTTPHeaderFieldValueConvertible {
  public init?(headerFieldValue: HTTPHeaderFieldValue) {
    guard let date = DateFormatter.rfc1123.date(from:headerFieldValue.rawValue) else {
      return nil
    }
    self = date
  }
  
  public var headerFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:DateFormatter.rfc1123.string(from:self))!
  }
}
