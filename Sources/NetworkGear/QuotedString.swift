/* *************************************************************************************************
 QuotedString.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import yExtensions

/// A specifier to determine how to quote strings.
public enum QuotedStringMode: Sendable, Equatable {
  /// Quoted String for HTTP
  case http

  /// Quoted String for Internet Message
  case mime

  fileprivate var _escapableUTF8CodeUnitDecider: (UTF8.CodeUnit) -> Bool {
    switch self {
    case .http: \._canBeEscapedInHTTPQuotedText
    case .mime: \._canBeEscapedInMIMEQuotedText
    }
  }

  fileprivate var _availableUTF8CodeUnitDecider: (UTF8.CodeUnit) -> Bool {
    switch self {
    case .http: \._isAvailableInHTTPHeaderFieldValueQuotedText
    case .mime: \._isAvailableInMIMEQuotedText
    }
  }

  fileprivate func _validContent<S>(_ content: S) -> Bool where S: StringProtocol {
    let canBeEscaped = self._escapableUTF8CodeUnitDecider
    let isAvailable = self._availableUTF8CodeUnitDecider
    return content.utf8.allSatisfy({ canBeEscaped($0) || isAvailable($0) })
  }
}

extension StringProtocol {
  internal func _quotedString(for mode: QuotedStringMode) -> String? {
    let isAvailable: (UTF8.CodeUnit) -> Bool = mode._availableUTF8CodeUnitDecider
    let canBeEscaped: (UTF8.CodeUnit) -> Bool = mode._escapableUTF8CodeUnitDecider

    var resultUTF8 = Data()
    resultUTF8.append(._doubleQuotationMark) // "

    for byte in self.utf8 {
      if isAvailable(byte) {
        resultUTF8.append(byte)
      } else {
        guard canBeEscaped(byte) else {
          return nil
        }
        resultUTF8.append(._backslash) // \
        resultUTF8.append(byte)
      }
    }
    
    resultUTF8.append(._doubleQuotationMark)
    return String(data: resultUTF8, encoding: .utf8)
  }
  
  internal func _unquotedString(for mode: QuotedStringMode) -> String? {
    let myUTF8 = self.utf8
    var index = myUTF8.startIndex
    var escaped = false
    var count = 0
    var resultUTF8 = Data()

    let canBeEscaped: (UTF8.CodeUnit) -> Bool = mode._escapableUTF8CodeUnitDecider

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
        guard canBeEscaped(byte) else { return nil }
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

private final class _LazyQuotedStringBidirectionalConverter: @unchecked Sendable {
  private let _queue: DispatchQueue = .init(
    label: "jp.YOCKOW.NetworkGear.QuotedString",
    attributes: .concurrent
  )

  private var _quotedString: String?
  private var _content: (any StringProtocol & _BidirectionalUTF8ViewAvailableStringProtocol)?
  let mode: QuotedStringMode

  var quotedString: String {
    return _queue.sync(flags: .barrier) {
      guard let quotedString = self._quotedString else {
        guard let quotedString = self._content?._quotedString(for: mode) else {
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
        guard let content = self._quotedString?._unquotedString(for: mode) else {
          fatalError("`QuotedString`: Unexpected quoted string?!")
        }
        _content = content
        return content
      }
      return content._string
    }
  }

  init(quotedString: String, content: String, mode: QuotedStringMode) {
    self._quotedString = quotedString
    self._content = content
    self.mode = mode
  }

  init(quotedString: String, mode: QuotedStringMode) {
    self._quotedString = quotedString
    self._content = nil
    self.mode = mode
  }

  init<S>(content: S, mode: QuotedStringMode)
  where S: StringProtocol, S: _BidirectionalUTF8ViewAvailableStringProtocol {
    self._quotedString = nil
    self._content = content
    self.mode = mode
  }

  func appending<S>(_ otherContent: S) -> _LazyQuotedStringBidirectionalConverter?
  where S: StringProtocol {
    guard mode._validContent(otherContent) else {
      return nil
    }
    return _LazyQuotedStringBidirectionalConverter(
      content: self.content + otherContent,
      mode: mode
    )
  }

  func appending(_ other: _LazyQuotedStringBidirectionalConverter) -> _LazyQuotedStringBidirectionalConverter? {
    guard self.mode == other.mode else {
      // Different Modes
      let myContent = self.content
      guard other.mode._validContent(myContent) else {
        return nil
      }
      return _LazyQuotedStringBidirectionalConverter(
        content: myContent + other.content,
        mode: other.mode
      )
    }

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
      return _LazyQuotedStringBidirectionalConverter(
        quotedString: quotedString,
        content: content,
        mode: mode
      )
    case (let quotedString?, nil):
      return _LazyQuotedStringBidirectionalConverter(quotedString: quotedString, mode: mode)
    case (nil, let content?):
      return _LazyQuotedStringBidirectionalConverter(content: content, mode: mode)
    case (nil, nil):
      fatalError("Unexpected case?!")
    }
  }

  func divide(whereFirstPartMaxUTF8Count maxCount: Int) -> (_LazyQuotedStringBidirectionalConverter, _LazyQuotedStringBidirectionalConverter?) {
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
        assert(byte._canBeEscapedInHTTPQuotedText)
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
        _LazyQuotedStringBidirectionalConverter(content: content[..<currentIndex], mode: mode),
        _LazyQuotedStringBidirectionalConverter(content: content[currentIndex...], mode: mode)
      )
    }

    guard let quotedString = _quotedString  else  {
      fatalError("Unexpected state?!")
    }

    FastPath: if quotedString.isContiguousUTF8 {
      let quotedStringUTF8 = quotedString.utf8
      var currentCount = quotedStringUTF8.count
      if currentCount <= maxCount {
        return (self, nil)
      }

      if currentCount - maxCount < maxCount {
        // Start backwards from last byte of the content.
        var contentEndIndex = quotedStringUTF8.index(before: quotedStringUTF8.endIndex)
        while currentCount > maxCount {
          let lastContentByteIndex = quotedStringUTF8.index(before: contentEndIndex)

          // -- NOTE --
          // "A\B"
          //    ^ is escaped.
          // "A\\B"
          //     ^ is not escaped.

          let prevByteIndex = quotedStringUTF8.index(before: lastContentByteIndex)
          let isEscaped: Bool = (
            quotedStringUTF8[prevByteIndex]._isBackslash &&
            prevByteIndex > quotedStringUTF8.startIndex &&
            !quotedStringUTF8[quotedStringUTF8.index(before: prevByteIndex)]._isBackslash
          )
          contentEndIndex = isEscaped ? prevByteIndex : lastContentByteIndex
          currentCount -= isEscaped ? 2 : 1
        }
        return (
          _LazyQuotedStringBidirectionalConverter(quotedString: quotedString[..<contentEndIndex] + "\"", mode: mode),
          _LazyQuotedStringBidirectionalConverter(quotedString: "\"" + quotedString[contentEndIndex...], mode: mode)
        )
      }
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
      _LazyQuotedStringBidirectionalConverter(quotedString: #""\#(noDQs[..<currentIndex])""#, mode: mode),
      _LazyQuotedStringBidirectionalConverter(quotedString: #""\#(noDQs[currentIndex...])""#, mode: mode)
    )
  }
}

/// A type for "quoted string".
///
/// - Note: Conforming types are `HTTPQuotedString` and `MIMEQuotedString`.
public protocol QuotedStringProtocol: Sendable {
  /// Returns a quoted string whose characters are escaped by backslashes if necessary.
  var quotedString: String { get }

  /// Returns content of the quoted string.
  var content: String { get }

  init?<S>(quoting content: S) where S: StringProtocol

  func appending(_ other: Self) -> Self

  func appending<S>(content: S) -> Self? where S: StringProtocol

  /// This function divides the quoted string into two quoted strings,
  /// where the count of first one's UTF-8 reporesentation is less than or equal to `maxCount`.
  ///
  /// - Parameters:
  ///   * maxCount: The maximum count of the first part's UTF-8 representation which must be greater than 3.
  ///
  /// - Returns: Two quoted strings.
  ///            The second one may be `nil` if the count of the whole quoted string is less than or equal to `maxCount`.
  func divide(whereFirstPartMaxUTF8Count maxCount: Int) -> (Self, Self?)
}

extension QuotedStringProtocol {
  internal var utf8Count: Int { self.quotedString.utf8.count }
}

/// A representation of `quoted-string` for HTTP.
public struct HTTPQuotedString: Sendable, QuotedStringProtocol {
  private let _converter: _LazyQuotedStringBidirectionalConverter

  public var quotedString: String { _converter.quotedString }

  public var content: String { _converter.content }

  private init(_converter converter: _LazyQuotedStringBidirectionalConverter) {
    assert(converter.mode == .http)
    self._converter = converter
  }

  internal init(quotedString: String, content: String) {
    assert(quotedString._unquotedString(for: .http) == content)
    self.init(_converter: .init(quotedString: quotedString, content: content, mode: .http))
  }

  internal init(quotedString: String) {
    assert(!quotedString._unquotedString(for: .http).isNil)
    self.init(_converter: .init(quotedString: quotedString, mode: .http))
  }

  @usableFromInline
  internal init<S>(content: S) where S: StringProtocol {
    assert(QuotedStringMode.http._validContent(content))
    self.init(_converter: .init(content: content._bidiUTF8ViewString, mode: .http))
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
    guard let quotedString = content._quotedString(for: .http) else {
      return nil
    }
    self.init(quotedString: quotedString, content: content._string)
  }

  public func appending(_ other: HTTPQuotedString) -> HTTPQuotedString {
    return HTTPQuotedString(_converter: self._converter.appending(other._converter)!)
  }

  public func appending<S>(content: S) -> HTTPQuotedString? where S: StringProtocol {
    guard let newConverter = self._converter.appending(content._string) else {
      return nil
    }
    return HTTPQuotedString(_converter: newConverter)
  }

  @usableFromInline
  internal func appending<T>(_token token: T) -> HTTPQuotedString where T: HTTPTokenStringProtocol {
    assert(QuotedStringMode.http._validContent(token._string))
    return HTTPQuotedString(_converter: self._converter.appending(token._string)!)
  }

  @inlinable
  public func appending(token: HTTPTokenString) -> HTTPQuotedString {
    self.appending(_token: token)
  }

  @inlinable
  public func appending(token: HTTPTokenSubstring) -> HTTPQuotedString {
    self.appending(_token: token)
  }

  public func divide(whereFirstPartMaxUTF8Count maxCount: Int) -> (HTTPQuotedString, HTTPQuotedString?) {
    let (converter1, conveter2) = self._converter.divide(whereFirstPartMaxUTF8Count: maxCount)
    return (HTTPQuotedString(_converter: converter1), conveter2.map({ HTTPQuotedString(_converter: $0) }))
  }
}

@available(*, deprecated, renamed: "HTTPQuotedString")
public typealias QuotedString = HTTPQuotedString

/// A representation of `quoted-string` for MIME.
///
/// - Note: This type holds optional leading/trailing `CFWS` when the instance is created by a parser.
///         On the other hand, leading/trailing `CFWS` may be discarded by some operations (i.g. `divide(whereFirstPartMaxUTF8Count:)`),
///         because RFC 5322 says:
///
///         > Semantically, neither the optional `CFWS` outside of the quote characters nor the quote characters themselves are part of the `quoted-string`.
public struct MIMEQuotedString: Sendable, QuotedStringProtocol {
  private let _converter: _LazyQuotedStringBidirectionalConverter

  public let leadingComments: [MIMEComment]?

  public var quotedString: String { _converter.quotedString }

  public var content: String { _converter.content }

  public let trailingComments: [MIMEComment]?

  private init(
    _converter converter: _LazyQuotedStringBidirectionalConverter,
    leadingComments: [MIMEComment]?,
    trailingComments: [MIMEComment]?
  ) {
    assert(converter.mode == .mime)
    self._converter = converter
    self.leadingComments = leadingComments
    self.trailingComments = trailingComments
  }

  internal init(
    leadingComments: [MIMEComment]?,
    quotedString: String,
    content: String,
    trailingComments: [MIMEComment]?
  ) {
    assert(quotedString._unquotedString(for: .mime) == content)
    self.init(
      _converter: .init(quotedString: quotedString, content: content, mode: .mime),
      leadingComments: leadingComments,
      trailingComments: trailingComments
    )
  }

  internal init(
    leadingComments: [MIMEComment]?,
    quotedString: String,
    trailingComments: [MIMEComment]?
  ) {
    assert(!quotedString._unquotedString(for: .mime).isNil)
    self.init(
      _converter: .init(quotedString: quotedString, mode: .mime),
      leadingComments: leadingComments,
      trailingComments: trailingComments
    )
  }

  @usableFromInline
  internal init<S>(
    leadingComments: [MIMEComment]?,
    content: S,
    trailingComments: [MIMEComment]?
  ) where S: StringProtocol {
    assert(QuotedStringMode.mime._validContent(content))
    self.init(
      _converter: .init(content: content._bidiUTF8ViewString, mode: .mime),
      leadingComments: leadingComments,
      trailingComments: trailingComments
    )
  }

  public init?<S>(quoting content: S) where S: StringProtocol {
    guard let quotedString = content._quotedString(for: .mime) else {
      return nil
    }
    self.init(
      leadingComments: nil,
      quotedString: quotedString,
      content: content._string,
      trailingComments: nil
    )
  }

  public func appending(_ other: MIMEQuotedString) -> MIMEQuotedString {
    func __concatenate(_ comments1: [MIMEComment]?, _ comments2: [MIMEComment]?) -> [MIMEComment]? {
      switch (comments1, comments2) {
      case (nil, nil):
        return nil
      case (_?, nil):
        return comments1
      case (nil, _?):
        return comments2
      case (let c1?, let c2?):
        return c1 + c2
      }
    }

    return MIMEQuotedString(
      _converter: self._converter.appending(other._converter)!,
      leadingComments: __concatenate(self.leadingComments, other.leadingComments),
      trailingComments: __concatenate(self.trailingComments, other.trailingComments),
    )
  }

  public func appending<S>(content: S) -> MIMEQuotedString? where S: StringProtocol {
    guard let newConverter = self._converter.appending(content._string) else {
      return nil
    }
    return MIMEQuotedString(
      _converter: newConverter,
      leadingComments: self.leadingComments,
      trailingComments: self.trailingComments
    )
  }

  public func divide(whereFirstPartMaxUTF8Count maxCount: Int) -> (MIMEQuotedString, MIMEQuotedString?) {
    let (converter1, conveter2) = self._converter.divide(whereFirstPartMaxUTF8Count: maxCount)
    return (
      MIMEQuotedString(_converter: converter1, leadingComments: nil, trailingComments: nil),
      conveter2.map({ MIMEQuotedString(_converter: $0, leadingComments: nil, trailingComments: nil) })
    )
  }
}

/// A parser to pull out a quoted string for HTTP.
public struct HTTPQuotedStringParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = HTTPQuotedString

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public func parse() -> (output: HTTPQuotedString, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isDoubleQuotationMark
    ) else {
      return nil
    }

    var contentUTF8 = Data()
    while let codeUnit: UTF8.CodeUnit = (
      self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isAvailableInHTTPHeaderFieldValueQuotedText
      ) ?? self.parseHTTPQuotedPair(from: &currentIndex)
    ) {
      contentUTF8.append(codeUnit)
    }

    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isDoubleQuotationMark
    ) else {
      return nil
    }

    return (
      HTTPQuotedString(
        quotedString: input[..<currentIndex]._string,
        content: String(decoding: contentUTF8, as: UTF8.self)
      ),
      currentIndex
    )
  }
}

extension HTTPQuotedString: _InitializableWithParser {
  public init?<S>(validating quotedString: S) where S: StringProtocol {
    self.init(quotedString, parser: HTTPQuotedStringParser<S>.self)
  }
}

/// A parser to pull out a quoted string for MIME.
public struct MIMEQuotedStringParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = MIMEQuotedString

  public struct Configuration: Sendable {
    public var cfwsParsingConfiguration: MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.Configuration

    public init(cfwsParsingConfiguration: MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.Configuration = .init()) {
      self.cfwsParsingConfiguration = cfwsParsingConfiguration
    }
  }

  let input: Input
  let utf8: Input.UTF8View

  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration ?? .init()
  }

  private enum _Element: Sendable {
    case fws
    case fwsAndQuotedContent(UTF8.CodeUnit)
    case quotedContent(UTF8.CodeUnit)
  }

  private func _parseElement(from index: inout Input.UTF8View.Index) -> _Element? {
    var currentIndex = index

    func __parseQuotedContent() -> UTF8.CodeUnit? {
      return self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isAvailableInMIMEQuotedText
      ) ?? self.parseMIMEQuotedPair(from: &currentIndex)
    }

    if let _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex) {
      if let quotedContent = __parseQuotedContent() {
        index = currentIndex
        return .fwsAndQuotedContent(quotedContent)
      }
      index = currentIndex
      return .fws
    } else {
      guard let quotedContent = __parseQuotedContent() else {
        return nil
      }
      index = currentIndex
      return .quotedContent(quotedContent)
    }
  }

  public func parse() -> (output: MIMEQuotedString, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    var leadingComments: [MIMEComment]? = nil
    if let leadingCFWS = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: configuration.cfwsParsingConfiguration
    ) {
      leadingComments = leadingCFWS
    }

    let quoteStartIndex = currentIndex
    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isDoubleQuotationMark
    ) else {
      return nil
    }

    var fwsExists = false
    var contentUTF8 = Data()
    PARSE_ELEMENT: while let element = _parseElement(from: &currentIndex) {
      switch element {
      case .fws:
        fwsExists = true
        contentUTF8.append(._space)
        break PARSE_ELEMENT
      case .fwsAndQuotedContent(let codeUnit):
        fwsExists = true
        contentUTF8.append(._space)
        contentUTF8.append(codeUnit)
      case .quotedContent(let codeUnit):
        contentUTF8.append(codeUnit)
      }
    }

    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isDoubleQuotationMark
    ) else {
      return nil
    }
    let quoteEndIndex = currentIndex

    var trailingComments: [MIMEComment]? = nil
    if let trailingCFWS = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: configuration.cfwsParsingConfiguration
    ) {
      trailingComments = trailingCFWS
    }

    let content = String(decoding: contentUTF8, as: UTF8.self)
    let output: MIMEQuotedString = fwsExists ? MIMEQuotedString(
      leadingComments: leadingComments,
      content: content,
      trailingComments: trailingComments
    ) : MIMEQuotedString(
      leadingComments: leadingComments,
      quotedString: input[quoteStartIndex..<quoteEndIndex]._string,
      content: content,
      trailingComments: trailingComments
    )
    return (output, currentIndex)
  }
}

extension MIMEQuotedString: _InitializableWithParser {
  @available(*, deprecated, renamed: "init(parsing:)")
  public init?<S>(validating quotedString: S) where S: StringProtocol {
    self.init(quotedString, parser: MIMEQuotedStringParser<S>.self)
  }

  public init?<S>(parsing quotedString: S, configuration: MIMEQuotedStringParser<S>.Configuration? = nil) where S: StringProtocol {
    self.init(quotedString, parser: MIMEQuotedStringParser<S>.self, configuration: configuration)
  }
}

/// A parser to pull out a quoted string.
public struct QuotedStringParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = any QuotedStringProtocol

  public struct Configuration: Sendable {
    public var mode: QuotedStringMode

    public init(mode: QuotedStringMode) {
      self.mode = mode
    }

    public static var `default`: Self { .init(mode: .http) }
  }

  internal let input: Input
  public var configuration: Configuration

  public var mode: QuotedStringMode {
    get { self.configuration.mode }
    set { self.configuration.mode = newValue }
  }

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.configuration = configuration ?? .default
  }


  public mutating func parse() -> (output: any QuotedStringProtocol, endIndex: Input.Index)? {
    switch mode {
    case .http:
      return HTTPQuotedStringParser<Input>.parse(input)
    case .mime:
      return MIMEQuotedStringParser<Input>.parse(input)
    }
  }
}
