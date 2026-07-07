/* *************************************************************************************************
 HTTPHeaderFieldName.swift
   © 2017-2020,2023-2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// # HeaderFieldName
/// Represents HTTP Header Field Name
public struct HTTPHeaderFieldName: Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  @usableFromInline
  internal private(set) var _string: ASCIICaseInsensitiveString

  public private(set) var rawValue: String {
    get {
      _string.description
    }
    set {
      assert(newValue.utf8.allSatisfy(\._isAvailableInHTTPHeaderFieldName))
      _string = ASCIICaseInsensitiveString(newValue)
    }
  }

  public static func ==(lhs: HTTPHeaderFieldName, rhs: HTTPHeaderFieldName) -> Bool {
    return lhs._string == rhs._string
  }

  @inlinable
  internal init<S>(_validatedString string: S) where S: StringProtocol {
    self._string = ASCIICaseInsensitiveString(string)
  }

  @inlinable
  public init?<S>(rawValue: S) where S: StringProtocol {
    if rawValue.isEmpty { return nil }
    guard rawValue.utf8.allSatisfy(\._isAvailableInHTTPHeaderFieldName) else { return nil }
    self.init(_validatedString: rawValue)
  }

  public init(_ token: HTTPTokenString) {
    self._string = ASCIICaseInsensitiveString(token._string)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self._string)
  }
  
  // Workaround for https://bugs.swift.org/browse/SR-10734
  #if compiler(>=5.0) && compiler(<5.1)
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

public struct HTTPHeaderFieldNameParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldName

  private var _parser: HTTPTokenParser<Input>

  public init(input: Input) {
    self._parser = HTTPTokenParser<Input>(input: input)
  }

  public mutating func parse() -> (output: HTTPHeaderFieldName, endIndex: Input.Index)? {
    guard let tokenResult = _parser.parse() else {
      return nil
    }
    return (output: HTTPHeaderFieldName(tokenResult.output), endIndex: tokenResult.endIndex)
  }
}
