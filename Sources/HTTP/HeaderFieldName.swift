/* *************************************************************************************************
 HeaderFieldName.swift
   © 2017-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import BonaFideCharacterSet

 /**
 
 # HeaderFieldName
 Represents HTTP Header Field Name
 
 */
public struct HeaderFieldName /* : RawRepresentable */ { // See https://bugs.swift.org/browse/SR-10734
  public let rawValue : String
  private let _lowercasedRawValue : String
  
  public init?(rawValue:String) {
    if rawValue.isEmpty { return nil }
    guard rawValue.consists(of:.httpHeaderFieldNameAllowed) else { return nil }
    self.rawValue = rawValue
    self._lowercasedRawValue = rawValue.lowercased()
  }
}

extension HeaderFieldName: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String
  public init(stringLiteral value: String) {
    self.init(rawValue: value)!
  }
}

extension HeaderFieldName: Equatable {
  public static func ==(lhs:HeaderFieldName, rhs:HeaderFieldName) -> Bool {
    return lhs._lowercasedRawValue == rhs._lowercasedRawValue
  }
}

extension HeaderFieldName: Hashable {
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self._lowercasedRawValue)
  }
}
