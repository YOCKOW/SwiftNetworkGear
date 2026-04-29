/* *************************************************************************************************
 StringProtocol+QuotedString.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

private let _DQUOTE: Unicode.UTF8.CodeUnit = 0x22
private let _BACKSLASH: Unicode.UTF8.CodeUnit = 0x5C

extension StringProtocol {
  /// See https://tools.ietf.org/html/rfc7230#section-3.2.6
  internal var _quotedString: String? {
    var resultUTF8 = Data()
    resultUTF8.append(_DQUOTE) // "

    for byte in self.utf8 {
      guard byte._canBeEscapedInQuotedText else { return nil }
      if byte._isAvailableInHTTPHeaderFieldValueQuotedText {
        resultUTF8.append(byte)
      } else {
        resultUTF8.append(_BACKSLASH) // \
        resultUTF8.append(byte)
      }
    }
    
    resultUTF8.append(_DQUOTE)
    return String(data: resultUTF8, encoding: .utf8)
  }
  
  internal var _unquotedString: String? {
    let myUTF8 = self.utf8
    var index = myUTF8.startIndex
    var escaped = false
    var count = 0
    var resultUTF8 = Data()

    ITERATE_UTF8: while index < myUTF8.endIndex {
      count += 1

      let byte = myUTF8[index]
      let nextIndex = myUTF8.index(after: index)

      if index == myUTF8.startIndex {
        guard byte == _DQUOTE else {
          return nil
        }
        index = nextIndex
        continue
      } else if nextIndex == myUTF8.endIndex {
        guard !escaped && byte == _DQUOTE else {
          return nil
        }
        break ITERATE_UTF8
      }


      if !escaped && byte == _BACKSLASH {
        escaped = true
      } else {
        guard byte._canBeEscapedInQuotedText else { return nil }
        resultUTF8.append(byte)
        escaped = false
      }
      index = nextIndex
    }

    guard count >= 2 else {
      return nil
    }
    
    return String(data: resultUTF8, encoding: .utf8)
  }
}
