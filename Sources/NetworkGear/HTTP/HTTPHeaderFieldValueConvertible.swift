/* *************************************************************************************************
 HTTPHeaderFieldValueConvertible.swift
   © 2018,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that can be converted to/from an instance of `HeaderFieldValue`.
public protocol HTTPHeaderFieldValueConvertible: Hashable {
  init?(_: HTTPHeaderFieldValue)
  init?(_: HTTPHeaderFieldValue, userInfo: [AnyHashable: Any]?)
  var httpHeaderFieldValue: HTTPHeaderFieldValue { get }
}

extension HTTPHeaderFieldValueConvertible {
  /// Default implementation.
  ///
  /// Note: `userInfo` is always ignored when this default implementation is used.
  public init?(_ httpHeaderFieldValue: HTTPHeaderFieldValue, userInfo: [AnyHashable: Any]?) {
    self.init(httpHeaderFieldValue)
  }
}

extension Encodable where Self: HTTPHeaderFieldValueConvertible {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(httpHeaderFieldValue.rawValue)
  }
}

extension Decodable where Self: HTTPHeaderFieldValueConvertible {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    guard let value = HTTPHeaderFieldValue(rawValue: rawValue) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid string for HTTP field value.")
    }
    guard let instance = Self(value) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid string for \(Self.self).")
    }
    self = instance
  }
}
