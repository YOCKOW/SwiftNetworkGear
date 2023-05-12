/* *************************************************************************************************
 HTTPHeaderFieldName.swift
   © 2017-2020,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

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
    guard rawValue.unicodeScalars.allSatisfy(\.isAllowedInHTTPHeaderFieldName) else { return nil }
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

extension HTTPHeaderFieldName: Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let desc = try container.decode(String.self)
    guard let instance = HTTPHeaderFieldName(rawValue: desc) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "'\(desc)' is invalid for HTTP header field name.")
    }
    self = instance
  }
}

extension HTTPHeaderFieldName: CodingKey {
  public var stringValue: String {
    return rawValue
  }

  public init?(stringValue: String) {
    self.init(rawValue: stringValue)
  }

  public var intValue: Int? {
    return nil
  }

  public init?(intValue: Int) {
    return nil
  }
}
