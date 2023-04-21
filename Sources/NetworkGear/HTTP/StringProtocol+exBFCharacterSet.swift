/* *************************************************************************************************
 StringProtocol+exBFCharacterSet.swift
   © 2018,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import yExtensions

internal func _trim<S>(_ string: S) -> String where S: StringProtocol {
  return string.trimmingUnicodeScalars(where: { $0.latestProperties.isWhitespace || $0._isNewline })
}

// Derived from https://github.com/YOCKOW/SwiftBonaFideCharacterSet/blob/main/Sources/BonaFideCharacterSet/StringProtocol%2BCharacterExpressionSet%2BUnicodeScalarSet.swift

private let _hex: [Unicode.Scalar] = ["0", "1", "2", "3", "4", "5", "6", "7",
                                      "8", "9", "A", "B", "C", "D", "E", "F"]
extension UInt8 {
  fileprivate var _percentEncoded: String.UnicodeScalarView {
    return .init(["%", _hex[Int(self >> 4)], _hex[Int(self & 0x0F)]])
  }
}
extension Unicode.Scalar {
  fileprivate var _utf8: AnyRandomAccessCollection<UInt8> {
    #if compiler(>=5.1)
    if #available(macOS 10.15, *) {
      return .init(self.utf8)
    }
    #endif

    let value = self.value
    if value <= 0x7F {
      return .init([UInt8(value)])
    } else if value <= 0x07FF {
      return .init([UInt8(0b11000000) | UInt8(value >> 6),
                    UInt8(0b10000000) | UInt8(value & 0b00111111)])
    } else if value <= 0xFFFF {
      return .init([UInt8(0b11100000) | UInt8(value >> 12),
                    UInt8(0b10000000) | UInt8(value >> 6 & 0b00111111),
                    UInt8(0b10000000) | UInt8(value & 0b00111111)])
    } else if value <= 0x1FFFFF {
      return .init([UInt8(0b11110000) | UInt8(value >> 18),
                    UInt8(0b10000000) | UInt8(value >> 12 & 0b00111111),
                    UInt8(0b10000000) | UInt8(value >> 6 & 0b00111111),
                    UInt8(0b10000000) | UInt8(value & 0b00111111)])
    } else {
      fatalError("Unexpected Unicode Scalar Value.")
    }
  }

  fileprivate var _percentEncoded: String.UnicodeScalarView {
    return .init(self._utf8.flatMap({ $0._percentEncoded }))
  }
}
extension StringProtocol {
  public func addingPercentEncoding(whereAllowedUnicodeScalars isAllowedUnicodeScalar: (Unicode.Scalar) throws -> Bool) rethrows -> String? {
    var output = String.UnicodeScalarView()
    for scalar in self.unicodeScalars {
      if try isAllowedUnicodeScalar(scalar) {
        output.append(scalar)
      } else {
        output.append(contentsOf: scalar._percentEncoded)
      }
    }
    return String(output)
  }
}
