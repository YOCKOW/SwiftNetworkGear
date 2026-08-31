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

internal protocol _SubstringOutputParser: _InputAccessibleParser where Output == Input.SubSequence {
  mutating func parse() -> Input.Index?
}

extension _SubstringOutputParser {
  @inlinable
  mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    guard let index: Input.Index = self.parse() else { return nil }
    return (self.input[..<index], index)
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
  // Note: Avoid https://github.com/swiftlang/swift/issues/44143

  @inlinable
  func readCurrentCodeUnit(at currentIndex: inout Input.UTF8View.Index) -> Unicode.UTF8.CodeUnit? {
    guard currentIndex < self.utf8.endIndex else { return nil }
    let byte = self.utf8[currentIndex]
    self.utf8.formIndex(after: &currentIndex)
    return byte
  }

  @inlinable
  func readCurrentCodeUnit(
    at currentIndex: inout Input.UTF8View.Index,
    ifAllowedCodeUnit isAllowedCodeUnit: (Unicode.UTF8.CodeUnit) throws -> Bool
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
  func parseSpaces(
    from currentIndex: inout Input.UTF8View.Index,
    minCount: Int = 1,
    maxCount: Int = .max
  ) -> Input.SubSequence? {
    return self.parseString(
      from: &currentIndex,
      minCount: minCount,
      maxCount: maxCount,
      while: \._isHTTPWhitespace
    )
  }

  @inlinable
  func parseMIMEWhitespaces(
    from currentIndex: inout Input.UTF8View.Index,
    minCount: Int = 1,
    maxCount: Int = .max
  ) -> Input.SubSequence? {
    return self.parseString(
      from: &currentIndex,
      minCount: minCount,
      maxCount: maxCount,
      while: \._isMIMEWhitespace
    )
  }

  @inlinable
  func parseInt<T>(
    _ type: T.Type = Int.self,
    from  currentIndex: inout Input.UTF8View.Index,
    minNumberOfDigits: Int = 1,
    maxNumberOfDigits: Int = .max,
    radix: Int = 10
  ) -> T? where T: FixedWidthInteger {
    assert(1 < radix && radix <= 36)
    let digitValidator: (Unicode.UTF8.CodeUnit) -> Bool = ({
      if radix <= 10 {
        return { unit in
          return 0x30 <= unit && unit < 0x30 + radix
        }
      } else {
        return { unit in
          return (
            unit._isDigit ||
            (0x41 <= unit && unit < 0x41 + radix - 10) ||
            (0x61 <= unit && unit < 0x61 + radix - 10)
          )
        }
      }
    })()
    guard let intDescription = self.parseString(
      from: &currentIndex,
      minCount: minNumberOfDigits,
      maxCount: maxNumberOfDigits,
      while: digitValidator
    ) else {
      return nil
    }
    return T(intDescription, radix: radix)
  }
}

@usableFromInline
internal protocol _InitializableWithParser {}
extension _InitializableWithParser {
  @usableFromInline
  init?<S, P>( _ string: S, parser: P.Type, configuration: P.Configuration?)
  where S: StringProtocol, P: StringParser, P.Input == S, P.Output == Self {
    guard let parsedResult = P.parse(string, configuration: configuration),
          parsedResult.endIndex == string.endIndex else {
      return nil
    }
    self = parsedResult.output
  }

  @usableFromInline
  init?<S, P>( _ string: S, parser: P.Type)
  where S: StringProtocol, P: StringParser, P.Input == S, P.Output == Self {
    self.init(string, parser: parser, configuration: nil)
  }
}


/// A parser to parse an integer.
public struct DigitParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = Int

  public struct Configuration {
    public let minNumberOfDigits: Int
    public let maxNumberOfDigits: Int
    public let radix: Int

    public init(
      minNumberOfDigits: Int = 1,
      maxNumberOfDigits: Int = .max,
      radix: Int = 10
    ) {
      self.minNumberOfDigits = minNumberOfDigits
      self.maxNumberOfDigits = maxNumberOfDigits
      self.radix = radix
    }
  }

  let input: Input
  let utf8: Input.UTF8View
  let configuration: Configuration?

  public var minNumberOfDigits: Int { configuration?.minNumberOfDigits ?? 1 }
  public var maxNumberOfDigits: Int { configuration?.maxNumberOfDigits ?? .max }
  public var radix: Int { configuration?.radix ?? 10 }

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  public init(
    input: Input,
    minNumberOfDigits: Int,
    maxNumberOfDigits: Int,
    radix: Int = 10
  ) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = .init(
      minNumberOfDigits: minNumberOfDigits,
      maxNumberOfDigits: maxNumberOfDigits,
      radix: radix
    )
  }

  public mutating func parse() -> (output: Int, endIndex: Input.Index)? {
    var index = self.utf8.startIndex
    guard let integer = self.parseInt(
      from: &index,
      minNumberOfDigits: minNumberOfDigits,
      maxNumberOfDigits: maxNumberOfDigits,
      radix: radix
    ) else {
      return nil
    }
    return (integer, index)
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

/// A parser to parse `LWSP`(Linear White-space), which is different from `FWS`.
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

/// A parser to parse `FWS`, which is different from `LWSP`.
///
/// - Refernce:
///     * [RFC 5322 §3.2.2](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.2)
public struct FoldingWhiteSpaceParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = Input.SubSequence

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    // Implementation Note:
    //   FWS = ([*WSP CRLF] 1*WSP)

    var currentIndex = utf8.startIndex

    func `__parse[*WSP CRLF]`() -> Input.Index? {
      var index = currentIndex
      _ = self.parseMIMEWhitespaces(from: &index)
      guard let _ = CRLFParser<Input.SubSequence>.parse(input, from: &index) else {
        return nil
      }
      return index
    }

    if let wspCRLFIndex = `__parse[*WSP CRLF]`() {
      currentIndex = wspCRLFIndex
    }

    guard let _ = self.parseMIMEWhitespaces(from: &currentIndex) else {
      return nil
    }

    return (input[..<currentIndex], currentIndex)
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

  public mutating func parse() -> (output: Output, endIndex: Input.Index)? {
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
    return (
      output: (firstResult.output, secondResult.output),
      endIndex: secondResult.endIndex
    )
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
      minCount: Int = 1,
      maxCount: Int = .max,
      eachConfiguration: Optional<([RepeatParser.Output]) -> RepeatParser.Configuration?> = nil
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

  public mutating func parse() -> (output: Output, endIndex: Input.Index)? {
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

  public mutating func parse() -> (output: Output, endIndex: Input.Index)? {
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


/// A parser to parse the output of `ContentParser` trimming leading/trailing whitespaces.
public struct TrimmingParser<Input, ContentParser>: StringParser, _UTF8Parser
where Input: StringProtocol, ContentParser: StringParser, ContentParser.Input == Input.SubSequence {
  public typealias Output = ContentParser.Output
  public typealias Configuration = ContentParser.Configuration

  let input: Input
  let utf8: Input.UTF8View
  public var configuration: Configuration?

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  public init(input: Input) {
    self.init(input: input, configuration: nil)
  }

  private var _result: (output: Output, endIndex: Input.Index)? = nil
  private var _parsed: Bool = false
  public mutating func parse() -> (output: ContentParser.Output, endIndex: Input.Index)? {
    if _parsed {
      return _result
    }

    defer {
      _parsed = true
    }

    var currentIndex = utf8.startIndex

    func __consumeWhitespaces() {
      _ = self.parseString(from: &currentIndex, while: { $0._isHTTPWhitespace || $0._isNewline })
    }

    __consumeWhitespaces()
    guard let content = ContentParser.parse(
      input,
      from: &currentIndex,
      configuration: configuration
    ) else {
      return nil
    }
    __consumeWhitespaces()
    _result = (content, currentIndex)
    return _result
  }
}

/// Parser for ":" followed by a string that can be parsed by `FollowerParser`.
internal struct ColonFollowedBy<FollowerParser, Input>: StringParser, _UTF8Parser
where FollowerParser: StringParser,
      FollowerParser.Input == Input.SubSequence,
      Input: StringProtocol {
  typealias Output = FollowerParser.Output
  typealias Configuration = FollowerParser.Configuration

  let input: Input
  let utf8: Input.UTF8View
  let configuration: Configuration?

  init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  init(input: Input) {
    self.init(input: input, configuration: nil)
  }

  mutating func parse() -> (output: FollowerParser.Output, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex
    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isColon) else {
      return nil
    }
    var follower = FollowerParser(input: input[currentIndex...], configuration: configuration)
    return follower.parse()
  }
}
