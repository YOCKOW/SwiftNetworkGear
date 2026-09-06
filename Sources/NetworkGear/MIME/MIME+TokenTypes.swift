/* *************************************************************************************************
 MIME+TokenTypes.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// Representation of `word` defined in [RFC 5322 §3.2.5](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.5).
public struct MIMEWord: Sendable {
  private enum _Entity: Sendable {
    case atom(MIMEAtom)
    case quotedString(MIMEQuotedString)
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

  fileprivate var leadingComments: [MIMEComment]? {
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

  fileprivate var trailingComments: [MIMEComment]? {
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

  public init(_ atom: MIMEAtom) {
    self._entity = .atom(atom)
  }

  public init(_ quotedString: MIMEQuotedString) {
    self._entity = .quotedString(quotedString)
  }
}

public struct MIMEWordParserConfiguration: Sendable {
  public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

  @inlinable
  public init(cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default) {
    self.cfwsParserConfiguration = cfwsParserConfiguration
  }

  public static let `default`: MIMEWordParserConfiguration = .init()
}

public struct MIMEWordParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = MIMEWord

  public typealias Configuration = MIMEWordParserConfiguration

  let input: Input

  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEWord, endIndex: Input.Index)? {
    var currentIndex = input.startIndex

    func __parseCFWS() -> Optional<[MIMEComment]?> {
      if let cfws = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(
        input,
        from: &currentIndex,
        configuration: configuration.cfwsParserConfiguration
      ) {
        return cfws
      }
      return Optional<[MIMEComment]?>.none
    }

    var leadingComments: [MIMEComment]? = nil
    if let leadingCFWS = __parseCFWS() {
      leadingComments = leadingCFWS
    }

    var partialWord: MIMEWord? = nil
    if let atomCore = _MIMEAtomCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) {
      partialWord = MIMEWord(MIMEAtom(
        leadingComments: nil,
        _validatedText: atomCore._string,
        trailingComments: nil)
      )
    } else if let qsCore = _MIMEQuotedStringCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) {
      partialWord = MIMEWord(qsCore)
    }

    guard var word = partialWord else {
      return nil
    }
    word.leadingComments = leadingComments
    if let trailingCFWS = __parseCFWS() {
      word.trailingComments = trailingCFWS
    }

    return (word, currentIndex)
  }
}

extension MIMEWord: _InitializableWithParser {
  public init?<S>(parsing string: S) where S: StringProtocol {
    self.init(string, parser: MIMEWordParser<S>.self)
  }
}

/// Representation of `phrase` defined in [RFC 5322 §3.2.5](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.5).
public struct MIMEPhrase: Sendable {
  @usableFromInline
  internal private(set) var _words: [MIMEWord]

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
  public func word(at index: Int) -> MIMEWord {
    return _words[index]
  }
}

public struct MIMEPhraseParserConfiguration: Sendable {
  public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

  @inlinable
  public init(cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default) {
    self.cfwsParserConfiguration = cfwsParserConfiguration
  }

  public static let `default`: MIMEPhraseParserConfiguration = .init()
}

/// A parser to parse a `phrase`.
public struct MIMEPhraseParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = MIMEPhrase

  public typealias Configuration = MIMEPhraseParserConfiguration

  @usableFromInline
  let input: Input

  public var configuration: Configuration

  @inlinable
  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  @inlinable
  public mutating func parse() -> (output: MIMEPhrase, endIndex: Input.Index)? {
    var delegateParser = RepetitionParser<Input, MIMEWordParser>(input: input, minCount: 1)
    guard let (words, endIndex) = delegateParser.parse() else {
      return nil
    }
    let phrase = MIMEPhrase(_words: words)
    return (phrase, endIndex)
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

  let input: Input

  let utf8: Input.UTF8View

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
