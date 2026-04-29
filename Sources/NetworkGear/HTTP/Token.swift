/* *************************************************************************************************
 Token.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

// Simple Lexer for HTTP header field values

private let _DQUOTE: Unicode.UTF8.CodeUnit = 0x22
private let _BACKSLASH: Unicode.UTF8.CodeUnit = 0x5C

internal class _Token {
  private let _utf8: Data

  internal init<S>(_ utf8: S) where S: Sequence, S.Element == Unicode.UTF8.CodeUnit {
    self._utf8 = Data(utf8)
  }
  
  internal var _string: String {
    return String(data: _utf8, encoding: .utf8)!
  }
  
  internal class _QuotedString: _Token {
    internal override var _string: String {
      return super._string._unquotedString!
    }
  }
  
  internal class _RawString: _Token {}
  
  internal class _Separator: _Token {}
}

private enum _Processing { case whitespace, quotedString, rawString }

extension StringProtocol {
  internal var _tokens: [_Token]? {
    var processing: _Processing = .whitespace
    var tokens: [_Token] = []
    
    var escaped = false
    var utf8: Data? = nil
    for byte in self.utf8 {
      switch processing {
      case .whitespace:
        if byte._isSpace || byte._isHorizontalTab { continue }

        utf8 = Data([byte])
        if byte == _DQUOTE {
          processing = .quotedString
        } else if byte._isAvailableInHTTPToken {
          processing = .rawString
        } else if byte._isRFC2616Separator {
          tokens.append(_Token._Separator(utf8!))
          utf8 = nil
          processing = .whitespace
        } else {
          return nil
        }
        
      case .quotedString:
        guard utf8 != nil else { fatalError("Unexpected.") }
        guard byte._canBeEscapedInQuotedText else { return nil }
        utf8!.append(byte)
        if !escaped {
          if byte == _BACKSLASH {
            escaped = true
            continue
          } else if byte == _DQUOTE {
            tokens.append(_Token._QuotedString(utf8!))
            utf8 = nil
            processing = .whitespace
          }
        }
        escaped = false
      
      case .rawString:
        guard utf8 != nil else { fatalError("Unexpected.") }
        if byte._isAvailableInHTTPToken {
          utf8!.append(byte)
        } else if byte._isRFC2616Separator {
          tokens.append(_Token._RawString(utf8!))
          if byte._isSpace || byte._isHorizontalTab {
            processing = .whitespace
          } else if byte == _DQUOTE {
            // is it right?
            utf8 = Data([byte])
            processing = .quotedString
          } else {
            tokens.append(_Token._Separator(Data([byte])))
            utf8 = nil
            processing = .whitespace
          }
        } else {
          return nil
        }
      }
    }
    
    switch processing {
    case .whitespace:
      break
    case .quotedString:
      // not closed...
      return nil
    case .rawString:
      tokens.append(_Token._RawString(utf8!))
    }
    
    return tokens
  }
}
