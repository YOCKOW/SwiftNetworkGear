/* *************************************************************************************************
 UInt+HeaderFieldValueConvertible.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
extension UInt: HTTPHeaderFieldValueConvertible {
  public init?(_ value: HTTPHeaderFieldValue) {
    self.init(value.rawValue)
  }
  
  public var httpHeaderFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.description)!
  }
}
