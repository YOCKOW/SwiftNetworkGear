/* *************************************************************************************************
 HTTPHeaderFieldName.swift
   © 2017-2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import BonaFideCharacterSet

/// # HeaderFieldName
/// Represents HTTP Header Field Name
public struct HTTPHeaderFieldName: Equatable, Hashable, RawRepresentable {
  public typealias RawValue = String
  public private(set) var rawValue: String
  private var _lowercasedName: String
  
  public static func ==(lhs: HTTPHeaderFieldName, rhs: HTTPHeaderFieldName) -> Bool {
    return lhs._lowercasedName == rhs._lowercasedName
  }
  
  public init?(rawValue: String) {
    if rawValue.isEmpty { return nil }
    guard rawValue.consists(of:.httpHeaderFieldNameAllowed) else { return nil }
    self.rawValue = rawValue
    self._lowercasedName = rawValue.lowercased()
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self._lowercasedName)
  }
  
  // Workaround for https://bugs.swift.org/browse/SR-10734
  #if compiler(>=5.0)
  public var hashValue: Int {
    return self._lowercasedName.hashValue
  }
  
  public func _rawHashValue(seed: Int) -> Int {
    var hasher = Hasher()
    self.hash(into: &hasher)
    return hasher.finalize()
  }
  #endif
}

extension HTTPHeaderFieldName: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String
  public init(stringLiteral value: String) {
    self.init(rawValue: value)!
  }
}
