/* *************************************************************************************************
 MIME+TokenTypes.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// Representation of `word` defined in [RFC 5322 §3.2.5](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.5).
public struct MIMEWord: Sendable, _SandwichedByOptionalCFWS {
  fileprivate enum _Entity: Sendable, _EitherMappable {
    case atom(MIMEAtom)
    case quotedString(MIMEQuotedString)

    typealias _Left = MIMEAtom
    typealias _Right = MIMEQuotedString

    init(_ atom: MIMEAtom) {
      self = .atom(atom)
    }

    init(_ quotedString: MIMEQuotedString) {
      self = .quotedString(quotedString)
    }
  }

  private var _entity: _Entity

  public var isAtom: Bool {
    guard case .atom = self._entity else {
      return false
    }
    return true
  }

  public var atom: MIMEAtom? {
    guard case .atom(let atom) = self._entity else {
      return nil
    }
    return atom
  }

  public var isQuotedString: Bool {
    guard case .quotedString = self._entity else {
      return false
    }
    return true
  }

  public var quotedString: MIMEQuotedString? {
    guard case .quotedString(let quotedString) = self._entity else {
      return nil
    }
    return quotedString
  }

  public internal(set) var leadingComments: [MIMEComment]? {
    get {
      switch self._entity {
      case .atom(let atom): return atom.leadingComments
      case .quotedString(let quotedString): return quotedString.leadingComments
      }
    }
    set {
      switch self._entity {
      case .atom(var atom):
        atom.leadingComments = newValue
        self._entity = .atom(atom)
      case .quotedString(var quotedString):
        quotedString.leadingComments = newValue
        self._entity = .quotedString(quotedString)
      }
    }
  }

  public internal(set) var trailingComments: [MIMEComment]? {
    get {
      switch self._entity {
      case .atom(let atom): return atom.trailingComments
      case .quotedString(let quotedString): return quotedString.trailingComments
      }
    }
    set {
      switch self._entity {
      case .atom(var atom):
        atom.trailingComments = newValue
        self._entity = .atom(atom)
      case .quotedString(var quotedString):
        quotedString.trailingComments = newValue
        self._entity = .quotedString(quotedString)
      }
    }
  }

  fileprivate init(_entity entity: _Entity) {
    self._entity = entity
  }

  public init(_ atom: MIMEAtom) {
    self.init(_entity: .atom(atom))
  }

  public init(_ quotedString: MIMEQuotedString) {
    self.init(_entity: .quotedString(quotedString))
  }
}

public struct MIMEWordParserConfiguration: Sendable, _SandwichedByOptionalCFWSParserConfiguration {
  public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

  @inlinable
  public init(cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default) {
    self.cfwsParserConfiguration = cfwsParserConfiguration
  }

  public static let `default`: MIMEWordParserConfiguration = .init()
}

public struct MIMEWordParser<Input>: StringParser, _SandwichedByOptionalCFWSParser
where Input: StringProtocol {
  public typealias Output = MIMEWord

  public typealias Configuration = MIMEWordParserConfiguration

  typealias CoreParserInput = Input.SubSequence
  struct CoreParser: StringParser {
    let input: CoreParserInput
    var configuration: Configuration

    init(input: CoreParserInput, configuration: Configuration?) {
      self.input = input
      self.configuration = configuration ?? .default
    }

    mutating func parse() -> (output: Output, endIndex: CoreParserInput.Index)? {
      guard let coreResult = _EitherParser<
        CoreParserInput,
        MIMEAtomParser<CoreParserInput>.CoreParser,
        MIMEQuotedStringParser<CoreParserInput>.CoreParser
      >.parse(
        input,
        configuration: .init(
          leftParserConfiguration: .init(cfwsParserConfiguration: configuration.cfwsParserConfiguration),
          rightParserConfiguration: .init(cfwsParserConfiguration: configuration.cfwsParserConfiguration)
        )
      ) else {
        return nil
      }
      return (
        MIMEWord(_entity: coreResult.output.map(type: MIMEWord._Entity.self)),
        coreResult.endIndex
      )
    }
  }

  @usableFromInline let input: Input

  public var configuration: Configuration

  public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration {
    return self.configuration.cfwsParserConfiguration
  }

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEWord, endIndex: Input.Index)? {
    var parser = _EitherOfTypesStartingWithOptionalCFWSParser<
      Input,
      MIMEAtomParser<Input>,
      MIMEQuotedStringParser<Input>
    >(
      input: input,
      configuration: .init(
        leftParserConfiguration: .init(cfwsParserConfiguration: cfwsParserConfiguration),
        rightParserConfiguration: .init(cfwsParserConfiguration: cfwsParserConfiguration)
      )
    )
    guard let parsedResult = parser.parse() else {
      return nil
    }
    return (
      MIMEWord(_entity: parsedResult.output.map(type: MIMEWord._Entity.self)),
      parsedResult.endIndex
    )
  }
}

extension MIMEWord: _InitializableWithParser {
  public init?<S>(parsing string: S) where S: StringProtocol {
    self.init(string, parser: MIMEWordParser<S>.self)
  }
}

/// Representation of `phrase` defined in [RFC 5322 §3.2.5](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.5).
public struct MIMEPhrase: Sendable, _StartsWithOptionalCFWS {
  @usableFromInline
  internal private(set) var _words: [MIMEWord]

  internal var leadingComments: [MIMEComment]? {
    @inlinable get {
      return _words.first?.leadingComments
    }
    set {
      var firstWord = _words.first!
      firstWord.leadingComments = newValue
      _words[0] = firstWord
    }
  }

  @usableFromInline
  internal init(_words words: [MIMEWord]) {
    assert(!words.isEmpty)
    self._words = words
  }

  public init(_ firstWord: MIMEWord, _ otherWords: MIMEWord...) {
    self._words = [firstWord] + otherWords
  }

  public mutating func append(_ word: MIMEWord) {
    self._words.append(word)
  }

  @inlinable
  public var wordCount: Int {
    return _words.count
  }

  @inlinable
  public func word(at index: Int) -> MIMEWord {
    return _words[index]
  }
}

public struct MIMEPhraseParserConfiguration: Sendable, _StartsWithOptionalCFWSParserConfiguration {
  public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

  @inlinable
  public init(cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default) {
    self.cfwsParserConfiguration = cfwsParserConfiguration
  }

  public static let `default`: MIMEPhraseParserConfiguration = .init()
}

/// A parser to parse a `phrase`.
public struct MIMEPhraseParser<Input>: StringParser, _StartsWithOptionalCFWSParser
where Input: StringProtocol {
  public typealias Output = MIMEPhrase

  public typealias Configuration = MIMEPhraseParserConfiguration

  @usableFromInline
  let input: Input

  public var configuration: Configuration

  public var cfwsParserConfiguration: CFWSParserConfiguration {
    get { configuration.cfwsParserConfiguration }
    set { configuration.cfwsParserConfiguration = newValue }
  }

  typealias PostLeadingCFWSInput = Input.SubSequence
  struct PostLeadingCFWSParser: StringParser {
    let input: PostLeadingCFWSInput
    var configuration: Configuration
    var cfwsParserConfiguration: CFWSParserConfiguration { configuration.cfwsParserConfiguration }

    init(input: PostLeadingCFWSInput, configuration: Configuration? = nil) {
      self.input = input
      self.configuration = configuration ?? .default
    }

    mutating func parse() -> (output: Output, endIndex: PostLeadingCFWSInput.Index)? {
      let wordConfig = MIMEWordParserConfiguration(cfwsParserConfiguration: cfwsParserConfiguration)

      guard let firstWordResult = MIMEWordParser<PostLeadingCFWSInput>.PostLeadingCFWSParser.parse(
        input,
        configuration: wordConfig
      ) else {
        return nil
      }

      var words: [MIMEWord] = [firstWordResult.output]
      var currentIndex = firstWordResult.endIndex

      if let restWords = RepetitionParser<PostLeadingCFWSInput.SubSequence, MIMEWordParser>.parse(
        input,
        from: &currentIndex,
        configuration: .init(
          minCount: 1,
          eachConfiguration: { _ in wordConfig}
        )
      ) {
        words.append(contentsOf: restWords)
      }
      return (MIMEPhrase(_words: words), currentIndex)
    }
  }

  @inlinable
  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEPhrase, endIndex: Input.Index)? {
    return self._parseWhole()
  }
}

/// A string representation for`unstructured` defined in [RFC 5322 §3.2.5](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.5).
public struct MIMEUnstructuredHeaderFieldValue: Sendable {
  public let rawValue: String

  fileprivate init(_rawValue rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct MIMEUnstructuredHeaderFieldValueParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = MIMEUnstructuredHeaderFieldValue

  @usableFromInline let input: Input

  @usableFromInline let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: MIMEUnstructuredHeaderFieldValue, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    var resultStringData = Data()
    while currentIndex < self.utf8.endIndex {
      if let _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        resultStringData.append(._space)
      }
      guard let vchar = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isVisible
      ) else {
        break
      }
      resultStringData.append(vchar)
    }
    
    if let _ = self.parseMIMEWhitespaces(from: &currentIndex) {
      resultStringData.append(._space)
    }

    return (
      MIMEUnstructuredHeaderFieldValue(_rawValue: resultStringData._string),
      currentIndex
    )
  }
}

extension MIMEUnstructuredHeaderFieldValue: _InitializableWithParser, RawRepresentable {
  public typealias RawValue = String

  public init?<S>(rawValue: S) where S: StringProtocol {
    self.init(rawValue, parser: MIMEUnstructuredHeaderFieldValueParser<S>.self)
  }
}
