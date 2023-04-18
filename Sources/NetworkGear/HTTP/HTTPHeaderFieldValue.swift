/* *************************************************************************************************
 HTTPHeaderFieldValue.swift
   © 2017-2019,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private func _valid_value(_ value:String) -> Bool {
  let scalars = value.unicodeScalars
  return (
    scalars.allSatisfy(\.isAllowedInHTTPHeaderFieldValue) &&
    scalars.first?._isVisible == true &&
    scalars.last?._isVisible == true
  )
}

/**
 
 # HeaderFieldValue
 Represents HTTP Header Field Value
 
 */
public struct HTTPHeaderFieldValue: RawRepresentable {
  public let rawValue : String
  public init?(rawValue:String) {
    if !rawValue.isEmpty {
      guard _valid_value(rawValue) else { return nil }
    }
    self.rawValue = rawValue
  }
}

extension HTTPHeaderFieldValue: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    guard _valid_value(value) else { fatalError("Invalid string: \(value)") }
    self.init(rawValue:value)!
  }
}

extension HTTPHeaderFieldValue: Equatable {}

extension HTTPHeaderFieldValue: Hashable {
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self.rawValue)
  }
}

