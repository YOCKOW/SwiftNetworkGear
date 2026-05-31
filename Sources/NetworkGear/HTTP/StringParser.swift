/* *************************************************************************************************
 StringParser.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import yExtensions

/// A type to parse a string (related to HTTP).
public protocol StringParser<Input, Output> where Input: StringProtocol {
  associatedtype Input
  associatedtype Output

  /// Initializes with `input` which is a target of the parser.
  init(input: Input)

  /// Parse the string which is passed when initialized.
  mutating func parse() -> (output: Output, endIndex: Input.Index)?
}

extension StringParser {
  @inlinable
  public static func parse(_ input: Input) -> (output: Output, endIndex: Input.Index)?  {
    var parser = Self.init(input: input)
    return parser.parse()
  }
}

internal protocol _UTF8Parser: StringParser {
  var string: Input { get }
  var utf8: Input.UTF8View { get }
}

extension _UTF8Parser {
  var utf8: Input.UTF8View { self.string.utf8 }
}

extension _UTF8Parser {
  @inlinable
  func readCurrentCodeUnit(
    at currentIndex: inout Input.UTF8View.Index,
    ifAllowedCodeUnit isAllowedCodeUnit: (Unicode.UTF8.CodeUnit) throws -> Bool = { _ in true }
  ) rethrows -> Unicode.UTF8.CodeUnit? {
    guard currentIndex < self.utf8.endIndex else { return nil }

    let byte = self.utf8[currentIndex]
    guard try isAllowedCodeUnit(byte) else { return nil }
    self.utf8.formIndex(after: &currentIndex)
    return byte
  }

  @inlinable
  func parseString(
    from currentIndex: inout Input.UTF8View.Index,
    minCount: Int = 1,
    maxCount: Int = .max,
    count: inout Int,
    while isAllowedCodeUnit: (Unicode.UTF8.CodeUnit) throws -> Bool
  ) rethrows -> Input.SubSequence? {
    assert(minCount > 0)
    count = 0
    let startIndex = currentIndex
    while let _ = try self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: isAllowedCodeUnit
    ) {
      count += 1
      if count == maxCount {
        break
      }
    }
    guard startIndex < currentIndex, count >= minCount else {
      currentIndex = startIndex
      return nil
    }
    return self.string[startIndex..<currentIndex]
  }

  @inlinable
  mutating func parseString(
    from currentIndex: inout Input.UTF8View.Index,
    minCount: Int = 1,
    maxCount: Int = .max,
    while isAllowedCodeUnit: (Unicode.UTF8.CodeUnit) throws -> Bool
  ) rethrows -> Input.SubSequence? {
    var dummyCount: Int = 0
    return try self.parseString(
      from: &currentIndex,
      minCount: minCount,
      maxCount: maxCount,
      count: &dummyCount,
      while: isAllowedCodeUnit
    )
  }
}

internal protocol _InitializableWithParser {}
extension _InitializableWithParser {
  init?<S, P>( _ string: S, parser: P.Type)
  where S: StringProtocol, P: StringParser, P.Input == S, P.Output == Self {
    guard let parsedResult = P.parse(string),
          parsedResult.endIndex == string.endIndex else {
      return nil
    }
    self = parsedResult.output
  }
}

/// A type that represents `token` defined in
/// [RFC 9110 §5.6.2](https://datatracker.ietf.org/doc/html/rfc9110#section-5.6.2).
@dynamicMemberLookup
public struct HTTPTokenString: Sendable, Equatable, Hashable {
  @usableFromInline
  internal let _string: String

  internal init<S>(_alreadyValidatedString string: S) where S: StringProtocol {
    self._string = String(string)
  }

  public init?<S>(validating string: S) where S: StringProtocol {
    guard !string.isEmpty && string.utf8.allSatisfy(\._isAvailableInHTTPToken) else {
      return nil
    }
    self.init(_alreadyValidatedString: string)
  }

  public subscript<T>(dynamicMember dynamicMember: KeyPath<String, T>) -> T {
    return self._string[keyPath: dynamicMember]
  }

  @inlinable
  public func isASCIICaseInsensitivelyEqual(to string: String) -> Bool {
    return _string.isASCIICaseInsensitivelyEqual(to: string)
  }
}

extension HTTPTokenString: Sequence {
  public typealias Iterator = String.Iterator
  public typealias Element = String.Element
  public func makeIterator() -> String.Iterator { return self._string.makeIterator() }
}

extension HTTPTokenString: Collection, BidirectionalCollection {
  public typealias Index = String.Index
  public var startIndex: String.Index { self._string.startIndex }
  public var endIndex: String.Index { self._string.endIndex }
  public subscript(position: String.Index) -> String.Element { self._string[position] }
  public func index(after ii: String.Index) -> String.Index { self._string.index(after: ii) }
  public func index(before ii: String.Index) -> String.Index { self._string.index(before: ii) }
}

extension HTTPTokenString: CustomStringConvertible {
  public var description: String { self._string }
}

extension HTTPTokenString: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType

  public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType

  public init(stringLiteral value: String) {
    guard let content = HTTPTokenString(validating: value) else {
      fatalError("Invalid value for `token`?!")
    }
    self = content
  }
}

extension FixedWidthInteger {
  /// Creates a new integer value from the given `token` and `radix`.
  @inlinable
  public init?(_ token: HTTPTokenString, radix: Int = 10) {
    self.init(token._string, radix: radix)
  }
}


/// A parser to pull out an HTTP token.
public struct HTTPTokenParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = HTTPTokenString

  internal let string: Input
  internal let utf8: Input.UTF8View

  public init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  private var _result: (output: HTTPTokenString, endIndex: Input.Index)? = nil
  private var _parsed: Bool = false
  public mutating func parse() -> (output: HTTPTokenString, endIndex: Input.Index)? {
    if _parsed {
      return _result
    }
    
    defer {
      _parsed = true
    }

    var index = utf8.startIndex
    guard let rawToken = self.parseString(from: &index, while: \._isAvailableInHTTPToken) else {
      return nil
    }
    _result = (output: HTTPTokenString(_alreadyValidatedString: rawToken), endIndex: index)
    return _result
  }
}


/// A parser that succeeds in parsing only if both two parsers succeed in parsing.
public struct CombinedParser<Input, FirstParser, SecondParser>: StringParser
where Input: StringProtocol,
      FirstParser: StringParser, FirstParser.Input == Input,
      SecondParser: StringParser, SecondParser.Input == Input.SubSequence {
  public typealias Output = (firstOutput: FirstParser.Output, secondOutput: SecondParser.Output)

  private let _string: Input

  public init(input: Input) {
    self._string = input
  }

  private var _result: (output: Output, endIndex: Input.Index)? = nil
  private var _parsed: Bool = false
  public mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    if _parsed {
      return _result
    }

    defer {
      _parsed = true
    }
    guard let firstResult = FirstParser.parse(_string) else {
      return nil
    }
    guard let secondResult = SecondParser.parse(_string[firstResult.endIndex...]) else {
      return nil
    }
    _result = (
      output: (firstResult.output, secondResult.output),
      endIndex: secondResult.endIndex
    )
    return _result
  }
}

/// A parser that parses a string repeatedly using `RepeatParser`.
open class RepetitionParser<Input, RepeatParser>: StringParser
where Input: StringProtocol, RepeatParser: StringParser, RepeatParser.Input == Input.SubSequence {
  public typealias Output = Array<RepeatParser.Output>

  private let _string: Input

  // TODO: I want `minCount` and `maxCount` to be set by values in generics.
  //       The feature requires macOS >=26.0...😖

  /// The number of min count to repeat parsing.
  open var minCount: Int = 1

  /// The number of max count to repeat parsing.
  open var maxCount: Int = .max

  public required init(input: Input) {
    self._string = input
  }

  private var _result: (output: Output, endIndex: Input.Index)? = nil
  private var _parsed: Bool = false
  public final func parse() -> (output: Output, endIndex: Input.Index)? {
    if _parsed {
      return _result
    }

    defer {
      _parsed = true
    }

    var output: Output = []
    var index = _string.startIndex
    while let parsedResult = RepeatParser.parse(_string[index...]) {
      output.append(parsedResult.output)
      index = parsedResult.endIndex
      if output.count == maxCount {
        break
      }
    }
    guard index > _string.startIndex, output.count >= minCount else {
      return nil
    }
    return (output, index)
  }
}

/// A parser to parse a list for field value.
///
/// See [RFC 9110 §5.6](https://datatracker.ietf.org/doc/html/rfc9110#section-5.6).
public struct ListParser<Input, ElementParser>: StringParser, _UTF8Parser
where Input: StringProtocol, ElementParser: StringParser, ElementParser.Input == Input.SubSequence {
  public typealias Output = [ElementParser.Output]

  internal let string: Input
  internal let utf8: Input.UTF8View

  public init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  private var _result: (output: Output, endIndex: Input.Index)? = nil
  private var _parsed: Bool = false
  public mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    if _parsed {
      return _result
    }

    defer {
      _parsed = true
    }

    var elements: [ElementParser.Output] = []
    var index = utf8.startIndex

    /// Returns `true` if some whitespaces or commas are consumed.
    func __consumeOptionalWhiteSpacesAndCommas() -> Bool {
      return !self.parseString(from: &index, while: { $0._isHTTPWhitespace || $0._isComma }).isNil
    }

    while true {
      var parser = ElementParser(input: string[index...])
      if let (element, endIndex) = parser.parse() {
        elements.append(element)
        index = endIndex
      }
      if __consumeOptionalWhiteSpacesAndCommas() {
        continue
      } else {
        return (output: elements, endIndex: index)
      }
    }
  }
}
public typealias TokenListParser<Input> =
  ListParser<Input, HTTPTokenParser<Input.SubSequence>> where Input: StringProtocol
