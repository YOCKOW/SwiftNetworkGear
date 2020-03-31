/* *************************************************************************************************
 Date+HeaderFieldValueConvertible.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

extension Date: HTTPHeaderFieldValueConvertible {
  public init?(_ value: HTTPHeaderFieldValue) {
    guard let date = DateFormatter.rfc1123.date(from: value.rawValue) else {
      return nil
    }
    self = date
  }
  
  public var httpHeaderFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:DateFormatter.rfc1123.string(from:self))!
  }
}
