/* *************************************************************************************************
 QuotedString.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import yExtensions

extension StringProtocol {
  /// See https://tools.ietf.org/html/rfc7230#section-3.2.6
  internal var _quotedString: String? {
    var resultUTF8 = Data()
    resultUTF8.append(._doubleQuotationMark) // "

    for byte in self.utf8 {
      guard byte._canBeEscapedInQuotedText else { return nil }
      if byte._isAvailableInHTTPHeaderFieldValueQuotedText {
        resultUTF8.append(byte)
      } else {
        resultUTF8.append(._backslash) // \
        resultUTF8.append(byte)
      }
    }
    
    resultUTF8.append(._doubleQuotationMark)
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
        guard byte._isDoubleQuotationMark else {
          return nil
        }
        index = nextIndex
        continue
      } else if nextIndex == myUTF8.endIndex {
        guard !escaped && byte._isDoubleQuotationMark else {
          return nil
        }
        break ITERATE_UTF8
      }


      if !escaped && byte._isBackslash {
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
    private let _queue: DispatchQueue = .init(
      label: "jp.YOCKOW.NetworkGear.QuotedString",
      attributes: .concurrent
    )
    private var _quotedString: String?
    private var _content: (any StringProtocol & _BidirectionalUTF8ViewAvailableStringProtocol)?

    var quotedString: String {
      return _queue.sync(flags: .barrier) {
        guard let quotedString = self._quotedString else {
          guard let quotedString = self._content?._quotedString else {
            fatalError("`QuotedString`: Unexpected content?!")
          }
          _quotedString = quotedString
          return quotedString
        }
        return quotedString
      }
    }

    var content: String {
      return _queue.sync(flags: .barrier) {
        guard let content = self._content else {
          guard let content = self._quotedString?._unquotedString else {
            fatalError("`QuotedString`: Unexpected quoted string?!")
          }
          _content = content
          return content
        }
        return content._string
      }
    }

    init(quotedString: String, content: String) {
      self._quotedString = quotedString
      self._content = content
    }

    init(quotedString: String) {
      self._quotedString = quotedString
      self._content = nil
    }

    init<S>(content: S) where S: StringProtocol, S: _BidirectionalUTF8ViewAvailableStringProtocol {
      self._quotedString = nil
      self._content = content
    }

    func appending(_ other: _LazyBidirectionalConverter) -> _LazyBidirectionalConverter {
      var newQuotedString: String? = nil
      if let myQuotedString = self._quotedString,
         let otherQuotedString = other._quotedString {
        newQuotedString = myQuotedString._dropLastUTF8CodeUnit().appending(
          otherQuotedString._dropFirstUTF8CodeUnit()
        )
      }

      var newContent: String? = nil
      if let myContent = self._content,
         let otherContent = other._content {
        newContent = myContent.appending(otherContent)
      }

      if newQuotedString.isNil && newContent.isNil {
        newQuotedString = self.quotedString._dropLastUTF8CodeUnit().appending(
          other.quotedString._dropFirstUTF8CodeUnit()
        )
      }

      switch (newQuotedString, newContent) {
      case (let quotedString?, let content?):
        return _LazyBidirectionalConverter(quotedString: quotedString, content: content)
      case (let quotedString?, nil):
        return _LazyBidirectionalConverter(quotedString: quotedString)
      case (nil, let content?):
        return _LazyBidirectionalConverter(content: content)
      case (nil, nil):
        fatalError("Unexpected case?!")
      }
    }

    func divide(whereFirstPartMaxUTF8Count maxCount: Int) -> (_LazyBidirectionalConverter, _LazyBidirectionalConverter?) {
      precondition(maxCount > 3, "Too small value to divide.")

      if let content = _content {
        FAST_PATH: if content.utf8.withContiguousStorageIfAvailable({
          $0.count <= (maxCount - 2) / 2
        }) == true {
          return (self, nil)
        }

        let contentUTF8 = content.utf8 as any _BidirectionalUTF8View
        var currentCount = 2 // Two double quotation marks
        var currentIndex = contentUTF8.startIndex
        while currentIndex < contentUTF8.endIndex {
          let byte = contentUTF8[currentIndex]
          assert(byte._canBeEscapedInQuotedText)
          let increment = byte._isAvailableInHTTPHeaderFieldValueQuotedText ? 1 : 2
          guard currentCount + increment <= maxCount else {
            break
          }
          currentCount += increment
          contentUTF8.formIndex(after: &currentIndex)
        }
        if currentIndex == contentUTF8.endIndex {
          return (self, nil)
        }
        return (
          _LazyBidirectionalConverter(content: content[..<currentIndex]),
          _LazyBidirectionalConverter(content: content[currentIndex...])
        )
      }

      guard let quotedString = _quotedString  else  {
        fatalError("Unexpected state?!")
      }

      FAST_PATH: if quotedString.utf8.withContiguousStorageIfAvailable({
        $0.count <= maxCount
      }) == true {
        return (self, nil)
      }

      var currentCount = 2 // Two double quotation marks
      let noDQs = quotedString._dropUTF8CodeUnit(first: 1, last: 1)
      let noDQsUTF8 = noDQs.utf8
      var currentIndex = noDQs.startIndex
      while currentIndex < noDQs.endIndex {
        let byte = noDQsUTF8[currentIndex]
        let escaping = byte._isBackslash
        let increment = escaping ? 2 : 1
        guard currentCount + increment <= maxCount else {
          break
        }
        currentCount += increment
        noDQs.formIndex(after: &currentIndex)
        if escaping {
          assert(currentIndex < noDQs.endIndex)
          noDQs.formIndex(after: &currentIndex)
        }
      }
      if currentIndex == noDQs.endIndex {
        return (self, nil)
      }
      return (
        _LazyBidirectionalConverter(quotedString: #""\#(noDQs[..<currentIndex])""#),
        _LazyBidirectionalConverter(quotedString: #""\#(noDQs[currentIndex...])""#)
      )
    }
  }

  private let _converter: _LazyBidirectionalConverter

  /// Returns a quoted string whose characters are escaped by backslashes if necessary.
  public var quotedString: String { _converter.quotedString }

  /// Returns content of the quoted string.
  public var content: String { _converter.content }

  private init(_converter converter: _LazyBidirectionalConverter) {
    self._converter = converter
  }

  internal init(quotedString: String, content: String) {
    assert(quotedString._unquotedString == content)
    self.init(_converter: .init(quotedString: quotedString, content: content))
  }

  internal init(quotedString: String) {
    assert(!quotedString._unquotedString.isNil)
    self.init(_converter: .init(quotedString: quotedString))
  }

  @usableFromInline
  internal init<S>(content: S) where S: StringProtocol {
    assert(
      content.utf8.allSatisfy({
        $0._isAvailableInHTTPHeaderFieldValueQuotedText || $0._canBeEscapedInQuotedText
      })
    )
    self.init(_converter: .init(content: content._bidiUTF8ViewString))
  }

  @inlinable
  internal init<T>(_token token: T) where T: HTTPTokenStringProtocol {
    assert(token._string.utf8.allSatisfy(\._isAvailableInHTTPHeaderFieldValueQuotedText))
    self.init(content: token._string)
  }

  public init(token: HTTPTokenString) {
    self.init(_token: token)
  }

  public init(token: HTTPTokenSubstring) {
    self.init(_token: token)
  }

  public init?<S>(quoting content: S) where S: StringProtocol {
    guard let quotedString = content._quotedString else {
      return nil
    }
    self.init(quotedString: quotedString, content: content._string)
  }

  public func appending(_ other: QuotedString) -> QuotedString {
    return QuotedString(_converter: self._converter.appending(other._converter))
  }

  public func appending<S>(content: S) -> QuotedString? where S: StringProtocol {
    guard content.utf8.allSatisfy({
      $0._isAvailableInHTTPHeaderFieldValueQuotedText || $0._canBeEscapedInQuotedText
    }) else {
      return nil
    }
    return QuotedString(_converter: self._converter.appending(.init(content: content._string)))
  }

  @usableFromInline
  internal func appending<T>(_token token: T) -> QuotedString where T: HTTPTokenStringProtocol {
    assert(token._string.utf8.allSatisfy(\._isAvailableInHTTPHeaderFieldValueQuotedText))
    return QuotedString(_converter: self._converter.appending(.init(content: token._string)))
  }

  @inlinable
  public func appending(token: HTTPTokenString) -> QuotedString {
    self.appending(_token: token)
  }

  @inlinable
  public func appending(token: HTTPTokenSubstring) -> QuotedString {
    self.appending(_token: token)
  }

  /// This function divides the quoted string into two quoted strings,
  /// where the count of first one's UTF-8 reporesentation is less than or equal to `maxCount`.
  ///
  /// - Parameters:
  ///   * maxCount: The maximum count of the first part's UTF-8 representation which must be greater than 3.
  ///
  /// - Returns: Two quoted strings.
  ///            The second one may be `nil` if the count of the whole quoted string is less than or equal to `maxCount`.
  public func divide(whereFirstPartMaxUTF8Count maxCount: Int) -> (QuotedString, QuotedString?) {
    let (converter1, conveter2) = self._converter.divide(whereFirstPartMaxUTF8Count: maxCount)
    return (QuotedString(_converter: converter1), conveter2.map({ QuotedString(_converter: $0) }))
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
