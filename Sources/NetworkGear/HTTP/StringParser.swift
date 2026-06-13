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
  associatedtype Configuration = Never

  /// Creates a parser for `input` with `configuration`.
  init(input: Input, configuration: Configuration?)

  /// Creates a parser for `input` without configuration.
  init(input: Input)

  /// Parse the string which is passed when initialized.
  mutating func parse() -> (output: Output, endIndex: Input.Index)?
}

extension StringParser {
  public init(input: Input) {
    self.init(input: input, configuration: nil)
  }
}

extension StringParser where Configuration == Never {
  @available(*, unavailable, message: "Required `init(input: Input)` must be implemented in each type.")
  public init(input: Input) {
    fatalError()
  }

  public init(input: Input, configuration: Configuration?) {
    self.init(input: input)
  }
}

extension StringParser {
  @inlinable
  public static func parse(
    _ input: Input,
    configuration: Configuration? = nil
  ) -> (output: Output, endIndex: Input.Index)? {
    var parser = Self.init(input: input, configuration: configuration)
    return parser.parse()
  }

  /// Parses `input` from given `index` and returns `output`.
  /// `index` will be rewritten to the end index if parsing succeeds.
  @inlinable
  public static func parse<C>(
    _ input: C,
    from index: inout Input.Index,
    configuration: Configuration? = nil
  ) -> Output? where C: Collection, C.SubSequence == Input {
    guard let (output, endIndex) = Self.parse(input[index...], configuration: configuration) else {
      return nil
    }
    index = endIndex
    return output
  }
}

internal protocol _InputAccessibleParser: StringParser {
  var input: Input { get }
}

extension _InputAccessibleParser {
  @inlinable
  func parseASCIICaseInsensitivePrefix<S>(
    _ prefix: S,
    from index: inout Input.Index
  ) -> Input.SubSequence? where S: StringProtocol {
    let startIndex = index
    guard let endIndex = self.input[index...]._caseInsensitive._endIndex(ofPrefix: prefix) else {
      return nil
    }
    index = endIndex
    return self.input[startIndex..<endIndex]
  }

  @inlinable
  func parseASCIICaseInsensitivePrefix<S>(
    _ prefix: S,
    from index: inout Input.Index
  ) -> Input.SubSequence? where S: ASCIICaseInsensitiveStringProtocol {
    return self.parseASCIICaseInsensitivePrefix(prefix._string, from: &index)
  }
}

internal protocol _UTF8Parser: _InputAccessibleParser {
  var input: Input { get }
  var utf8: Input.UTF8View { get }
}

extension _UTF8Parser {
  var utf8: Input.UTF8View { self.input.utf8 }
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
    return self.input[startIndex..<currentIndex]
  }

  @inlinable
  func parseString(
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

  @inlinable
  func parseInt(
    from  currentIndex: inout Input.UTF8View.Index,
    minNumberOfDigits: Int = 1,
    maxNumberOfDigits: Int = .max,
    radix: Int = 10
  ) -> Int? {
    assert(1 < radix && radix <= 36)
    guard let intDescription = self.parseString(
      from: &currentIndex,
      minCount: minNumberOfDigits,
      maxCount: maxNumberOfDigits,
      while: { unit in
        if radix <= 10 {
          return 0x30 <= unit && unit < 0x30 + radix
        }

        // radix > 10
        return (
          unit._isDigit ||
          (0x41 <= unit && unit < 0x41 + radix - 10) ||
          (0x61 <= unit && unit < 0x61 + radix - 10)
        )
      }
    ) else {
      return nil
    }
    return Int(intDescription, radix: radix)
  }
}

@usableFromInline
internal protocol _InitializableWithParser {}
extension _InitializableWithParser {
  @usableFromInline
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

  internal let input: Input
  internal let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
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


public struct CRLFParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = Input.SubSequence

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
    var index = utf8.startIndex
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isCarriageReturn) else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isLineFeed) else {
      return nil
    }
    return (input[..<index], index)
  }
}

/// A parser to parse `LWSP`(Linear White-space).
///
/// - Refrence:
///     * [RFC 5234 Appendix B](https://datatracker.ietf.org/doc/html/rfc5234#appendix-B.1)
public struct LinearWhitespaceParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = Input.SubSequence

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
    var index = utf8.startIndex

    // Implementation Note:
    //   LWSP = *(WSP / CRLF WSP)
    //
    // i.e.) `CRLR` must be followed by `WSP`.

    func __parseWSPs() -> Bool {
      return !self.parseString(from: &index, while: \._isHTTPWhitespace).isNil
    }

    while index < utf8.endIndex {
      if __parseWSPs() {
        continue
      }

      let endIndexOfWSP = index
      guard let (_, endIndexOfCRLF) = CRLFParser<Input.SubSequence>.parse(
        input[endIndexOfWSP...]
      ) else {
        break
      }
      index = endIndexOfCRLF
      guard __parseWSPs() else {
        index = endIndexOfWSP
        break
      }
    }

    guard index > utf8.startIndex else {
      return nil
    }

    return (input[..<index], index)
  }
}

/// A parser that succeeds in parsing only if both two parsers succeed in parsing.
public struct CombinedParser<Input, FirstParser, SecondParser>: StringParser
where Input: StringProtocol,
      FirstParser: StringParser, FirstParser.Input == Input,
      SecondParser: StringParser, SecondParser.Input == Input.SubSequence {
  public typealias Output = (firstOutput: FirstParser.Output, secondOutput: SecondParser.Output)

  public struct Configuration {
    public let firstParserConfiguration: FirstParser.Configuration?
    public let secondParserConfiguration: SecondParser.Configuration?

    public init(
      _ firstParserConfiguration: FirstParser.Configuration?,
      _ secondParserConfiguration: SecondParser.Configuration?
    ) {
      self.firstParserConfiguration = firstParserConfiguration
      self.secondParserConfiguration = secondParserConfiguration
    }
  }

  private let _string: Input
  private let _configuration: Configuration?

  public init(input: Input, configuration: Configuration?) {
    self._string = input
    self._configuration = configuration
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
    guard let firstResult = FirstParser.parse(
      _string,
      configuration: _configuration?.firstParserConfiguration
    ) else {
      return nil
    }
    guard let secondResult = SecondParser.parse(
      _string[firstResult.endIndex...],
      configuration: _configuration?.secondParserConfiguration
    ) else {
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
public struct RepetitionParser<Input, RepeatParser>: StringParser
where Input: StringProtocol, RepeatParser: StringParser, RepeatParser.Input == Input.SubSequence {
  public typealias Output = Array<RepeatParser.Output>

  public struct Configuration {
    public var minCount: Int

    public var maxCount: Int

    /// Configuration generator.
    /// The argument of each closure is a partial result at that point.
    public var eachConfiguration: Optional<([RepeatParser.Output]) -> RepeatParser.Configuration?>

    public init(
      minCount: Int,
      maxCount: Int,
      eachConfiguration: Optional<([RepeatParser.Output]) -> RepeatParser.Configuration?>
    ) {
      self.minCount = minCount
      self.maxCount = maxCount
      self.eachConfiguration = eachConfiguration
    }
  }

  private let _string: Input
  private var _configuration: Configuration?

  /// The number of min count to repeat parsing.
  public var minCount: Int {
    get {
      return self._configuration?.minCount ?? 1
    }
    set {
      let newMinCount = max(0, newValue)
      guard var currentConfig = self._configuration else {
        self._configuration = Configuration(
          minCount: newMinCount,
          maxCount: .max,
          eachConfiguration: nil
        )
        return
      }
      currentConfig.minCount = newMinCount
      self._configuration = currentConfig
    }
  }

  /// The number of max count to repeat parsing.
  public var maxCount: Int {
    get {
      return self._configuration?.maxCount ?? .max
    }
    set {
      guard var currentConfig = self._configuration else {
        self._configuration = Configuration(
          minCount: 1,
          maxCount: newValue,
          eachConfiguration: nil
        )
        return
      }
      currentConfig.maxCount = newValue
      self._configuration = currentConfig
    }
  }

  public var eachConfiguration: Optional<([RepeatParser.Output]) -> RepeatParser.Configuration?> {
    get {
      return self._configuration?.eachConfiguration
    }
    set {
      guard var currentConfig = self._configuration else {
        self._configuration = Configuration(
          minCount: 1,
          maxCount: .max,
          eachConfiguration: newValue
        )
        return
      }
      currentConfig.eachConfiguration = newValue
      self._configuration = currentConfig
    }
  }

  public init(input: Input, configuration: Configuration?) {
    self._string = input
    self._configuration = configuration
  }

  @inlinable
  public init(
    input: Input,
    minCount: Int,
    maxCount: Int,
    eachConfiguration: Optional<([RepeatParser.Output]) -> RepeatParser.Configuration?>
  ) {
    self.init(
      input: input,
      configuration: Configuration(
        minCount: minCount,
        maxCount: maxCount,
        eachConfiguration: eachConfiguration
      )
    )
  }

  @inlinable
  public init(
    input: Input,
    minCount: Int
  ) {
    self.init(
      input: input,
      configuration: Configuration(
        minCount: minCount,
        maxCount: .max,
        eachConfiguration: nil
      )
    )
  }

  @inlinable
  public init(
    input: Input,
    maxCount: Int
  ) {
    self.init(
      input: input,
      configuration: Configuration(
        minCount: 1,
        maxCount: maxCount,
        eachConfiguration: nil
      )
    )
  }

  @inlinable
  public init(
    input: Input,
    minCount: Int,
    maxCount: Int
  ) {
    self.init(
      input: input,
      configuration: Configuration(
        minCount: minCount,
        maxCount: maxCount,
        eachConfiguration: nil
      )
    )
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

    var output: Output = []
    var index = _string.startIndex
    while let parsedResult = RepeatParser.parse(
      _string[index...],
      configuration: self._configuration?.eachConfiguration?(output)
    ) {
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

  public struct Configuration {
    /// Configuration generator.
    /// The argument of each closure is a partial result at that point.
    public var eachConfiguration: Optional<([ElementParser.Output]) -> ElementParser.Configuration?>
  }

  internal let input: Input
  internal let utf8: Input.UTF8View
  private var _configuration: Configuration?

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self._configuration = configuration
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
      var parser = ElementParser(
        input: input[index...],
        configuration: _configuration?.eachConfiguration?(elements)
      )
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
