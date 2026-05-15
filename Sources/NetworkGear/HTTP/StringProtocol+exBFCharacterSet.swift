/* *************************************************************************************************
 StringProtocol+exBFCharacterSet.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

internal func _trim<S>(_ string: S) -> String where S: StringProtocol {
  return string.trimmingUnicodeScalars(where: {
    let properties = $0.latestProperties
    return properties.isWhitespace || properties.isNewline
  })
}

private let _PERCENT: UInt8 = 0x25

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
    collection.append(_PERCENT)
    collection.append(__hex(of: self >> 4))
    collection.append(__hex(of: self & 0x0F))
  }
}

private extension Sequence where Self.Element == UInt8 {
  func _addingPercentEncoding(withAllowedBytes isAllowedByte: (UInt8) throws -> Bool) rethrows -> Data {
    var output = Data()
    for byte in self {
      if try byte != _PERCENT && isAllowedByte(byte) {
        output.append(byte)
      } else {
        byte._addPercentEncodedBytes(to: &output)
      }
    }
    return output
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
