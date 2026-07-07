/* *************************************************************************************************
 HTTPHeaderFieldValue.swift
   © 2017-2019,2023-2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private func _valid_value(_ value:String) -> Bool {
  let utf8 = value.utf8
  return (
    utf8.allSatisfy(\._isAvailableInHTTPHeaderFieldValue) &&
    utf8.first?._isVisible == true &&
    utf8.last?._isVisible == true
  )
}

/**
 
 # HeaderFieldValue
 Represents HTTP Header Field Value
 
 */
public struct HTTPHeaderFieldValue: RawRepresentable, Sendable {
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

extension HTTPHeaderFieldValue: Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let desc = try container.decode(String.self)
    guard let instance = HTTPHeaderFieldValue(rawValue: desc) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "'\(desc)' is invalid for HTTP header field value.")
    }
    self = instance
  }
}

