/* *************************************************************************************************
 MIMEAtom.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `atom` defined in [RFC 5322 §3.2.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.3).
public struct MIMEAtom: Sendable {
  public internal(set) var leadingComments: [MIMEComment]?

  public let text: String

  public internal(set) var trailingComments: [MIMEComment]?

  internal init(
    leadingComments: [MIMEComment]?,
    _validatedText text: String,
    trailingComments: [MIMEComment]?
  ) {
    self.leadingComments = leadingComments
    self.text = text
    self.trailingComments = trailingComments
  }
}

internal struct _MIMEAtomCoreParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  typealias Output = Input.SubSequence

  let input: Input
  let utf8: Input.UTF8View

  init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  mutating func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex
    guard let text = self.parseString(from: &currentIndex, while: \._isAvailableInAtomText) else {
      return nil
    }
    return (text, currentIndex)
  }
}

public struct MIMEAtomParserConfiguration: Sendable {
  public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

  @inlinable
  public init(cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default) {
    self.cfwsParserConfiguration = cfwsParserConfiguration
  }

  public static let `default`: MIMEAtomParserConfiguration = .init()
}

public struct MIMEAtomParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = MIMEAtom

  public typealias Configuration = MIMEAtomParserConfiguration

  @usableFromInline
  let input: Input

  @usableFromInline
  let utf8: Input.UTF8View

  public var configuration: Configuration

  @inlinable
  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEAtom, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    var leadingComments: [MIMEComment]? = nil
    if let leadingCFWS = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: configuration.cfwsParserConfiguration
    ) {
      leadingComments = leadingCFWS
    }

    guard let text = _MIMEAtomCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) else {
      return nil
    }

    var trailingComments: [MIMEComment]? = nil
    if let trailingCFWS = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: configuration.cfwsParserConfiguration
    ) {
      trailingComments = trailingCFWS
    }

    return (
      MIMEAtom(
        leadingComments: leadingComments,
        _validatedText: text._string,
        trailingComments: trailingComments
      ),
      currentIndex
    )
  }
}

extension MIMEAtom: _InitializableWithParser {
  public init?<S>(parsing string: S, configuration: MIMEAtomParser<S>.Configuration? = nil) where S: StringProtocol {
    self.init(string, parser: MIMEAtomParser<S>.self, configuration: configuration)
  }
}

/// Representation of `dot-atom` defined in [RFC 5322 §3.2.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.3).
public struct MIMEDotAtom: Sendable {
  public internal(set) var leadingComments: [MIMEComment]?

  /// `dot-atom-text`
  public let text: String

  public internal(set) var trailingComments: [MIMEComment]?

  @usableFromInline
  internal init(
    leadingComments: [MIMEComment]?,
    _validatedText text: String,
    trailingComments: [MIMEComment]?) {
    self.leadingComments = leadingComments
    self.text = text
    self.trailingComments = trailingComments
  }
}

internal struct _MIMEDotAtomCoreParser<Input>: StringParser, _UTF8Parser, _SubstringOutputParser
where Input: StringProtocol {
  typealias Output = Input.SubSequence

  let input: Input
  let utf8: Input.UTF8View

  init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  private func _parseDotAndAtext(from index: inout Input.Index) -> Bool {
    var currentIndex = index
    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod) else {
      return false
    }
    guard let _ = self.parseString(from: &currentIndex, while: \._isAvailableInAtomText) else {
      return false
    }
    index = currentIndex
    return true
  }

  @inlinable
  mutating func parse() -> Input.Index? {
    var currentIndex = self.utf8.startIndex
    guard let _ = self.parseString(from: &currentIndex, while: \._isAvailableInAtomText) else {
      return nil
    }
    while self._parseDotAndAtext(from: &currentIndex) {}
    return currentIndex
  }
}

public struct MIMEDotAtomParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = MIMEDotAtom

  public typealias Configuration = MIMEAtomParser<Input>.Configuration

  @usableFromInline
  let input: Input

  @usableFromInline
  let utf8: Input.UTF8View

  public var configuration: Configuration

  @inlinable
  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration ?? .default
  }

  private func _parseDotAndAtext(from index: inout Input.Index) -> Bool {
    var currentIndex = index
    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod) else {
      return false
    }
    guard let _ = self.parseString(from: &currentIndex, while: \._isAvailableInAtomText) else {
      return false
    }
    index = currentIndex
    return true
  }

  public mutating func parse() -> (output: MIMEDotAtom, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    var leadingComments: [MIMEComment]? = nil
    if let leadingCFWS = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: configuration.cfwsParserConfiguration
    ) {
      leadingComments = leadingCFWS
    }

    guard let text = _MIMEDotAtomCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) else {
      return nil
    }


    var trailingComments: [MIMEComment]? = nil
    if let trailingCFWS = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: configuration.cfwsParserConfiguration
    ) {
      trailingComments = trailingCFWS
    }

    return (
      MIMEDotAtom(
        leadingComments: leadingComments,
        _validatedText: text._string,
        trailingComments: trailingComments
      ),
      currentIndex
    )
  }
}

extension MIMEDotAtom: _InitializableWithParser {
  public init?<S>(parsing string: S, configuration: MIMEDotAtomParser<S>.Configuration? = nil) where S: StringProtocol {
    self.init(string, parser: MIMEDotAtomParser<S>.self, configuration: configuration)
  }
}
