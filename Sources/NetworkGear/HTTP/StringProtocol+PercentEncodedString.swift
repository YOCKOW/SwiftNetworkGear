/* *************************************************************************************************
 StringProtocol+PercentEncodedString.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import yExtensions

private extension UInt8 {
  func _addPercentEncodedBytes<C>(to collection: inout C)
  where C: RangeReplaceableCollection, C.Element == UInt8 {
    func __hex(of uint8: UInt8) -> UInt8 {
      assert(uint8 <= 0x0F)
      switch uint8 {
      case 0...9: return uint8 + 0x30 // "0"..."9"
      default: return uint8 - 10 + 0x41 // "A"..."F"
      }
    }
    collection.append(._percentSign)
    collection.append(__hex(of: self >> 4))
    collection.append(__hex(of: self & 0x0F))
  }

  var _hexValue: UInt8? {
    switch self {
    case 0x30...0x39: return self - 0x30
    case 0x41...0x5A: return self - 0x41 + 10
    case 0x61...0x7A: return self - 0x61 + 10
    default: return nil
    }
  }
}

private extension Sequence where Self.Element == UInt8 {
  func _addingPercentEncoding(withAllowedBytes isAllowedByte: (UInt8) throws -> Bool) rethrows -> Data {
    var output = Data()
    for byte in self {
      if try !byte._isPercentSign && isAllowedByte(byte) {
        output.append(byte)
      } else {
        byte._addPercentEncodedBytes(to: &output)
      }
    }
    return output
  }

  var _removingPercentEncoding: Data? {
    var result = Data()
    var myIterator = self.makeIterator()
    while let byte = myIterator.next() {
      if byte._isPercentSign {
        guard let h1 = myIterator.next(),
              let b1 = h1._hexValue,
              let h2 = myIterator.next(),
              let b2 = h2._hexValue else {
          return nil
        }
        result.append((b1 << 4) | b2)
      } else { // byte != _PERCENT
        result.append(byte)
      }
    }
    return result
  }
}

extension StringProtocol {
  public func addingPercentEncoding(
    usingStringEncoding stringEncoding: String.Encoding,
    whereAllowedUnicodeScalars isAllowedUnicodeScalar: (Unicode.Scalar) throws -> Bool
  ) rethrows -> String? {
    var outputData = Data()

    if stringEncoding == .utf8 {
      for scalar in self.unicodeScalars {
        if try isAllowedUnicodeScalar(scalar) {
          outputData.append(contentsOf: scalar.utf8)
        } else {
          scalar.utf8.forEach({ $0._addPercentEncodedBytes(to: &outputData) })
        }
      }
    } else { // stringEncoding != .utf8
      for scalar in self.unicodeScalars {
        guard let scalarData = String(scalar).data(using: stringEncoding) else {
          return nil
        }
        if try isAllowedUnicodeScalar(scalar) {
          outputData.append(contentsOf: scalarData)
        } else {
          var percentEncodedScalarData = Data()
          scalarData.forEach({ $0._addPercentEncodedBytes(to: &percentEncodedScalarData) })
          guard let percentEncoded = String(
            decoding: percentEncodedScalarData,
            as: Unicode.UTF8.self
          ).data(using: stringEncoding) else {
            return nil
          }
          outputData.append(contentsOf: percentEncoded)
        }
      }
    }
    return String(data: outputData, encoding: stringEncoding)
  }

  @inlinable
  public func addingPercentEncoding(whereAllowedUnicodeScalars isAllowedUnicodeScalar: (Unicode.Scalar) throws -> Bool) rethrows -> String? {
    return try self.addingPercentEncoding(
      usingStringEncoding: .utf8,
      whereAllowedUnicodeScalars: isAllowedUnicodeScalar
    )
  }

  public func addingPercentEncoding(
    usingStringEncoding stringEncoding: String.Encoding,
    whereAllowedASCIICharacters isAllowedASCIICharacter: (Unicode.UTF8.CodeUnit) throws -> Bool
  ) rethrows -> String? {
    guard let stringData: any Sequence<UInt8> = (stringEncoding == .utf8) ? self.utf8 : self.data(using: stringEncoding) else {
      return nil
    }
    let encodedData = try stringData._addingPercentEncoding(withAllowedBytes: {
      try $0 < 0x80 && isAllowedASCIICharacter($0)
    })
    return String(data: encodedData, encoding: .ascii)
  }

  @inlinable
  public func addingPercentEncoding(
    whereAllowedASCIICharacters isAllowedASCIICharacter: (Unicode.UTF8.CodeUnit) throws -> Bool
  ) rethrows -> String? {
    return try self.addingPercentEncoding(
      usingStringEncoding: .utf8,
      whereAllowedASCIICharacters: isAllowedASCIICharacter
    )
  }
}


/// A string that is encoded with [Percent-Encoding](https://datatracker.ietf.org/doc/html/rfc3986#section-2.1).
public struct PercentEncodedString: Sendable, Equatable, Hashable {
  public let encodedString: String

  public static func ==(lhs: PercentEncodedString, rhs: PercentEncodedString) -> Bool {
    return lhs.encodedString == rhs.encodedString
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.encodedString)
  }

  private final class _DecodedData: @unchecked Sendable {
    private let _queue: DispatchQueue = .init(
      label: "jp.YOCKOW.NetworkGear.PercentEncodedString",
      attributes: .concurrent
    )
    private var _decodedData: Data? = nil

    func decode(_ string: String) -> Data {
      return _queue.sync(flags: .barrier) {
        guard let decodedData = self._decodedData else {
          let decodedData = string.utf8._removingPercentEncoding!
          self._decodedData = decodedData
          return decodedData
        }
        return decodedData
      }
    }
  }
  private let _decodedData: _DecodedData = .init()

  public var decodedData: Data {
    return _decodedData.decode(self.encodedString)
  }

  /// Decodes percent-encoded string and returns a string using the given string encoding.
  public func decodedString(usingStringEncoding stringEncoding: String.Encoding) -> String? {
    return String(data: self.decodedData, encoding: stringEncoding)
  }

  /// Decodes percent-encoded string.
  @inlinable
  public var decodedString: String? {
    return self.decodedString(usingStringEncoding: .utf8)
  }

  /// - parameters:
  ///   - encodedString: A string that has been already **validated** as a percent-encoded string.
  ///
  /// - Note: This initializer should not be `public`.
  internal init(encodedString: String) {
    self.encodedString = encodedString
  }
}


/// A parser to parse a percent-encoded string.
public struct PercentEncodedStringParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = PercentEncodedString

  public struct Configuration {
    public let allowedNonEncodedUTF8CodeUnits: (Unicode.UTF8.CodeUnit) -> Bool

    public init(allowedNonEncodedUTF8CodeUnits: @escaping (Unicode.UTF8.CodeUnit) -> Bool = { $0._isVisible } ) {
      self.allowedNonEncodedUTF8CodeUnits = allowedNonEncodedUTF8CodeUnits
    }
  }

  let input: Input
  let utf8: Input.UTF8View
  public let configuration: Configuration

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration ?? .init()
  }

  public init(input: Input, allowedNonEncodedUTF8CodeUnits: @escaping (Unicode.UTF8.CodeUnit) -> Bool) {
    self.init(
      input: input,
      configuration: .init(allowedNonEncodedUTF8CodeUnits: allowedNonEncodedUTF8CodeUnits)
    )
  }

  public mutating func parse() -> (output: PercentEncodedString, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    func __parsePercentEncoded() -> Bool {
      var currentIndexForPercentEncoded = currentIndex
      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndexForPercentEncoded,
        ifAllowedCodeUnit: \._isPercentSign
      ) else {
        return false
      }
      guard let _ = self.parseString(
        from: &currentIndexForPercentEncoded,
        minCount: 2,
        maxCount: 2,
        while: \._isHexDigit
      ) else {
        return false
      }
      currentIndex = currentIndexForPercentEncoded
      return true
    }

    while currentIndex < self.utf8.endIndex {
      if __parsePercentEncoded() {
        continue
      }
      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: {
          !$0._isPercentSign && configuration.allowedNonEncodedUTF8CodeUnits($0)
        }
      ) else {
        break
      }
    }
    return (
      PercentEncodedString(encodedString: input[..<currentIndex]._string),
      currentIndex
    )
  }
}

extension PercentEncodedString: _InitializableWithParser {
  /// Creates an instance from given `string`.
  public init?<S>(
    validating string: S,
    configuration: PercentEncodedStringParser<S>.Configuration? = nil
  ) where S: StringProtocol {
    self.init(
      string,
      parser: PercentEncodedStringParser<S>.self,
      configuration: configuration
    )
  }

  /// Creates an instance from given `string`.
  public init?<S>(
    validating string: S,
    whereAllowedNonEncodedUTF8CodeUnits allowedNonEncodedUTF8CodeUnits: @escaping (Unicode.UTF8.CodeUnit) -> Bool
  ) where S: StringProtocol {
    self.init(
      validating: string,
      configuration: .init(allowedNonEncodedUTF8CodeUnits: allowedNonEncodedUTF8CodeUnits)
    )
  }
}
