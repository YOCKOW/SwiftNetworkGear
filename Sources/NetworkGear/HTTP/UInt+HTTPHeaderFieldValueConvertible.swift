/* *************************************************************************************************
 UInt+HeaderFieldValueConvertible.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
extension UInt: HTTPHeaderFieldValueConvertible {
  public init?(headerFieldValue: HTTPHeaderFieldValue) {
    self.init(headerFieldValue.rawValue)
  }
  
  public var headerFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.description)!
  }
}
