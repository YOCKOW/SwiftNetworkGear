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

/// A representation of `quoted-string`.
public struct QuotedString: Sendable {
  private final class _LazyBidirectionalConverter: @unchecked Sendable {
    private var _quotedString: String?
    private var _content: String?

    var quotedString: String {
      guard let quotedString = self._quotedString else {
        guard let quotedString = self._content?._quotedString else {
          fatalError("`QuotedString`: Unexpected content?!")
        }
        _quotedString = quotedString
        return quotedString
      }
      return quotedString
    }

    var content: String {
      guard let content = self._content else {
        guard let content = self._quotedString?._unquotedString else {
          fatalError("`QuotedString`: Unexpected quoted string?!")
        }
        _content = content
        return content
      }
      return content
    }

    init(quotedString: String, content: String) {
      self._quotedString = quotedString
      self._content = content
    }

    init(quotedString: String) {
      self._quotedString = quotedString
      self._content = nil
    }

    init(content: String) {
      self._quotedString = nil
      self._content = content
    }
  }

  private let _converter: _LazyBidirectionalConverter

  /// Returns a quoted string whose characters are escaped by backslashes if necessary.
  public var quotedString: String { _converter.quotedString }

  /// Returns content of the quoted string.
  public var content: String { _converter.content }

  internal init(quotedString: String, content: String) {
    assert(quotedString._unquotedString == content)
    self._converter = .init(quotedString: quotedString, content: content)
  }

  internal init(quotedString: String) {
    self._converter = .init(quotedString: quotedString)
  }

  internal init(content: String) {
    self._converter = .init(content: content)
  }
}

/// A parser to pull out a quoted string.
public struct QuotedStringParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = QuotedString

  internal let input: Input
  internal let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  private var _result: (output: QuotedString, endIndex: Input.Index)? = nil
  private var _parsed: Bool = false
  public mutating func parse() -> (output: QuotedString, endIndex: Input.Index)? {
    if _parsed {
      return _result
    }

    defer {
      _parsed = true
    }
    var index = utf8.startIndex
    guard let _ = self.readCurrentCodeUnit(
      at: &index, ifAllowedCodeUnit: { $0._isDoubleQuotationMark }
    ) else {
      return nil
    }
    guard index < utf8.endIndex else {
      return nil
    }

    var escaped = false
    var contentUTF8: [Unicode.UTF8.CodeUnit] = []
    while let codeUnit = self.readCurrentCodeUnit(
      at: &index,
      ifAllowedCodeUnit: {
        $0._isAvailableInHTTPHeaderFieldValueQuotedText ||
        $0._canBeEscapedInQuotedText
      }
    ) {
      if escaped {
        guard codeUnit._canBeEscapedInQuotedText else { return nil }
        escaped = false
        contentUTF8.append(codeUnit)
      } else if codeUnit._isDoubleQuotationMark {
        let quotedString = String(self.input[..<index])
        let content = String(decoding: contentUTF8, as: Unicode.UTF8.self)
        _result = (
          output: QuotedString(quotedString: quotedString, content: content),
          endIndex: index
        )
        return _result
      } else if codeUnit._isBackslash {
        escaped = true
      } else {
        guard codeUnit._isAvailableInHTTPHeaderFieldValueQuotedText else {
          return nil
        }
        contentUTF8.append(codeUnit)
      }
    }
    return nil
  }
}

extension QuotedString: _InitializableWithParser {
  public init?<S>(validating quotedString: S) where S: StringProtocol {
    self.init(quotedString, parser: QuotedStringParser<S>.self)
  }
}
