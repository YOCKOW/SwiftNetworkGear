/* *************************************************************************************************
 HTTPBinResponse.swift
   © 2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import NetworkGear

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

  public struct File: Decodable {
    public let content: String
    public let contentType: MIMEType
    public let filename: String

    public enum Key: String, CodingKey {
      case content
      case contentType = "content_type"
      case filename
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: Key.self)
      self.content = try container.decode(String.self, forKey: .content)
      self.contentType = try container.decode(MIMEType.self, forKey: .contentType)
      self.filename = try container.decode(String.self, forKey: .filename)
    }
  }

  public enum FileOrString: Decodable {
    case file(File)
    case string(String)

    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let file = try? container.decode(File.self) {
        self = .file(file)
        return
      }
      self = .string(try container.decode(String.self))
    }

    public var content: String {
      switch self {
      case .file(let file):
        return file.content
      case .string(let string):
        return string
      }
    }

    public var contentType: MIMEType? {
      guard case .file(let file) = self else {
        return nil
      }
      return file.contentType
    }

    public var filename: String? {
      guard case .file(let file) = self else {
        return nil
      }
      return file.filename
    }
  }

  public let data: String?
  public let files: Dictionary<String, FileOrString>?
  public let form: Dictionary<String, StringOrArray>?
  public let headers: Dictionary<String, String>

  public func headerValue(for key: String) -> String? {
    return headers.first(where: { $0.key.lowercased() == key.lowercased() })?.value
  }
}
