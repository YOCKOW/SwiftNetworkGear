/* *************************************************************************************************
 HTTPBinResponse.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public struct HTTPBinResponse: Decodable {
  public enum StringOrArray: Decodable, Equatable, ExpressibleByStringLiteral, ExpressibleByArrayLiteral {
    case string(String)
    case array([String])

    public init(from decoder: any Decoder) throws {
      let singleValueContainer = try decoder.singleValueContainer()
      if let string = try? singleValueContainer.decode(String.self) {
        self = .string(string)
        return
      }
      self = .array(try singleValueContainer.decode(Array<String>.self))
    }

    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
      self = .string(value)
    }

    public typealias ArrayLiteralElement = String
    public init(arrayLiteral elements: String...) {
      self = .array(elements)
    }
  }

  public let data: String?
  public let files: Dictionary<String, String>?
  public let form: Dictionary<String, StringOrArray>?
  public let headers: Dictionary<String, String>

  public func headerValue(for key: String) -> String? {
    return headers.first(where: { $0.key.lowercased() == key.lowercased() })?.value
  }
}
