/* *************************************************************************************************
 Token.swift
   © 2018,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// Simple Lexer for HTTP header field values

internal class _Token {
  private let _scalars: String.UnicodeScalarView
  internal init(_ scalars:String.UnicodeScalarView) {
    self._scalars = scalars
  }
  
  internal var _string: String {
    return String(self._scalars)
  }
  
  internal class _QuotedString: _Token {
    internal override var _string: String {
      return String(self._scalars)._unquotedString!
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
    var scalars: String.UnicodeScalarView? = nil
    for scalar in self.unicodeScalars {
      switch processing {
      case .whitespace:
        if scalar.latestProperties.isWhitespace { continue }
        
        scalars = .init([scalar])
        if scalar == "\"" {
          processing = .quotedString
        } else if scalar.isHTTPToken {
          processing = .rawString
        } else if scalar.isHTTPSeparator {
          tokens.append(_Token._Separator(scalars!))
          scalars = nil
          processing = .whitespace
        } else {
          return nil
        }
        
      case .quotedString:
        guard let _ = scalars else { fatalError("Unexpected.") }
        guard scalar.isHTTPEscapable else { return nil }
        scalars!.append(scalar)
        if !escaped {
          if scalar == "\\" {
            escaped = true
            continue
          } else if scalar == "\"" {
            tokens.append(_Token._QuotedString(scalars!))
            scalars = nil
            processing = .whitespace
          }
        }
        escaped = false
      
      case .rawString:
        guard let _ = scalars else { fatalError("Unexpected.") }
        if scalar.isHTTPToken {
          scalars!.append(scalar)
        } else if scalar.isHTTPSeparator {
          tokens.append(_Token._RawString(scalars!))
          if scalar.latestProperties.isWhitespace {
            processing = .whitespace
          } else if scalar == "\"" {
            // is it right?
            scalars = .init([scalar])
            processing = .quotedString
          } else {
            tokens.append(_Token._Separator(.init([scalar])))
            scalars = nil
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
      tokens.append(_Token._RawString(scalars!))
    }
    
    return tokens
  }
}
