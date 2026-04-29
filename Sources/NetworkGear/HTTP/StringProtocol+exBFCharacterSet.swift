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

extension StringProtocol {
  public func addingPercentEncoding(whereAllowedUnicodeScalars isAllowedUnicodeScalar: (Unicode.Scalar) throws -> Bool) rethrows -> String? {
    var outputUTF8 = Data()
    for scalar in self.unicodeScalars {
      if try isAllowedUnicodeScalar(scalar) {
        outputUTF8.append(contentsOf: scalar.utf8)
      } else {
        func __hex(of uint8: UInt8) -> UInt8 {
          assert(uint8 <= 0x0F)
          switch uint8 {
          case 0...9: return uint8 + 0x30 // "0"..."9"
          default: return uint8 - 10 + 0x41 // "A"..."F"
          }
        }
        for uint8 in scalar.utf8 {
          outputUTF8.append(0x25) // %
          outputUTF8.append(__hex(of: uint8 >> 4))
          outputUTF8.append(__hex(of: uint8 & 0x0F))
        }
      }
    }
    return String(data: outputUTF8, encoding: .utf8)
  }

  public func addingPercentEncoding(
    whereAllowedASCIICharacters isAllowedASCIICharacter: (Unicode.UTF8.CodeUnit) throws -> Bool
  ) rethrows -> String? {
    return try self.addingPercentEncoding(whereAllowedUnicodeScalars: {
      guard $0.value < 0x80 else {
        return false
      }
      return try isAllowedASCIICharacter(UInt8($0.value))
    })
  }
}
