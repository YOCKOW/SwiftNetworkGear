/* *************************************************************************************************
 MIMEAddress.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// Representation of `domain-literal` defined in [RFC 5322 §3.4.1](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4.1).
public struct MIMEDomainLiteral: Sendable {
  public internal(set) var leadingComments: [MIMEComment]?

  public let text: String

  public internal(set) var trailingComments: [MIMEComment]?

  internal init(
    leadingComments: [MIMEComment]?,
    _validatedText text: String,
    trailingComments: [MIMEComment]?
  ) {
    assert(
      text.hasPrefix("[") &&
      text.hasSuffix("]") &&
      text.dropFirst().dropLast().utf8.allSatisfy({
        $0._isAvailableInMIMEDomainLiteral || $0._isSpace
      })
    )
    self.leadingComments = leadingComments
    self.text = text
    self.trailingComments = trailingComments
  }
}

/// Representation of `addr-spec` defined in [RFC 5322 §3.4.1](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4.1).
public struct MIMEAddressSpecification: Sendable {
  /// Representation of `local-part` defined in [RFC 5322 §3.4.1](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4.1).
  public struct LocalPart: Sendable {
    private enum _Entity: Sendable {
      case dotAtom(MIMEDotAtom)
      case quotedString(MIMEQuotedString)
    }

    private var _entity: _Entity

    public var isDotAtom: Bool {
      guard case .dotAtom = self._entity else {
        return false
      }
      return true
    }

    public var dotAtom: MIMEDotAtom? {
      guard case .dotAtom(let dotAtom) = self._entity else {
        return nil
      }
      return dotAtom
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

    public fileprivate(set) var leadingComments: [MIMEComment]? {
      get {
        switch self._entity {
        case .dotAtom(let dotAtom): return dotAtom.leadingComments
        case .quotedString(let quotedString): return quotedString.leadingComments
        }
      }
      set {
        switch self._entity {
        case .dotAtom(var dotAtom):
          dotAtom.leadingComments = newValue
          self._entity = .dotAtom(dotAtom)
        case .quotedString(var quotedString):
          quotedString.leadingComments = newValue
          self._entity = .quotedString(quotedString)
        }
      }
    }


    public fileprivate(set) var trailingComments: [MIMEComment]? {
      get {
        switch self._entity {
        case .dotAtom(let dotAtom): return dotAtom.trailingComments
        case .quotedString(let quotedString): return quotedString.trailingComments
        }
      }
      set {
        switch self._entity {
        case .dotAtom(var dotAtom):
          dotAtom.trailingComments = newValue
          self._entity = .dotAtom(dotAtom)
        case .quotedString(var quotedString):
          quotedString.trailingComments = newValue
          self._entity = .quotedString(quotedString)
        }
      }
    }

    public mutating func removeLeadingComments() {
      self.leadingComments = nil
    }

    public mutating func removeTrailingComments() {
      self.trailingComments = nil
    }

    public init(_ dotAtom: MIMEDotAtom) {
      self._entity = .dotAtom(dotAtom)
    }

    public init(_ quotedString: MIMEQuotedString) {
      self._entity = .quotedString(quotedString)
    }
  }

  /// Representation of `domain` defined in [RFC 5322 §3.4.1](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4.1).
  public struct DomainPortion: Sendable {
    private enum _Entity: Sendable {
      case dotAtom(MIMEDotAtom)
      case domainLiteral(MIMEDomainLiteral)
    }

    private var _entity: _Entity

    public var isDotAtom: Bool {
      guard case .dotAtom = self._entity else {
        return false
      }
      return true
    }

    public var dotAtom: MIMEDotAtom? {
      guard case .dotAtom(let dotAtom) = self._entity else {
        return nil
      }
      return dotAtom
    }

    public var isDomainLiteral: Bool {
      guard case .domainLiteral = self._entity else {
        return false
      }
      return true
    }

    public var domainLiteral: MIMEDomainLiteral? {
      guard case .domainLiteral(let literal) = self._entity else {
        return nil
      }
      return literal
    }

    public fileprivate(set) var leadingComments: [MIMEComment]? {
      get {
        switch self._entity {
        case .dotAtom(let dotAtom): return dotAtom.leadingComments
        case .domainLiteral(let literal): return literal.leadingComments
        }
      }
      set {
        switch self._entity {
        case .dotAtom(var dotAtom):
          dotAtom.leadingComments = newValue
          self._entity = .dotAtom(dotAtom)
        case .domainLiteral(var literal):
          literal.leadingComments = newValue
          self._entity = .domainLiteral(literal)
        }
      }
    }


    public fileprivate(set) var trailingComments: [MIMEComment]? {
      get {
        switch self._entity {
        case .dotAtom(let dotAtom): return dotAtom.trailingComments
        case .domainLiteral(let literal): return literal.trailingComments
        }
      }
      set {
        switch self._entity {
        case .dotAtom(var dotAtom):
          dotAtom.trailingComments = newValue
          self._entity = .dotAtom(dotAtom)
        case .domainLiteral(var literal):
          literal.trailingComments = newValue
          self._entity = .domainLiteral(literal)
        }
      }
    }

    public mutating func removeLeadingComments() {
      self.leadingComments = nil
    }

    public mutating func removeTrailingComments() {
      self.trailingComments = nil
    }

    public init(_ dotAtom: MIMEDotAtom) {
      self._entity = .dotAtom(dotAtom)
    }

    public init(_ domainLiteral: MIMEDomainLiteral) {
      self._entity = .domainLiteral(domainLiteral)
    }
  }

  public let localPart: LocalPart

  public let domainPortion: DomainPortion

  @inlinable
  public init(localPart: LocalPart, domainPortion: DomainPortion) {
    self.localPart = localPart
    self.domainPortion = domainPortion
  }
}

extension MIMEAddressSpecification {
  public struct ParserConfiguration: Sendable {
    public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

    public init(
      cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default
    ) {
      self.cfwsParserConfiguration = cfwsParserConfiguration
    }

    public static let `default`: ParserConfiguration = .init()
  }
}

private struct _MIMEDomainLiteralCoreParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  typealias Output = String

  let input: Input
  let utf8: Input.UTF8View

  init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  mutating func parse() -> (output: String, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    var resultUTF8 = Data()

    guard let open = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isLeftSquareBracket
    ) else {
      return nil
    }
    resultUTF8.append(open)

    while currentIndex < self.utf8.endIndex {
      if let _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        resultUTF8.append(._space)
      }

      guard let dText = self.parseString(
        from: &currentIndex,
        while: \._isAvailableInMIMEDomainLiteral
      ) else {
        break
      }
      resultUTF8.append(contentsOf: dText.utf8)
    }

    if let _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex) {
      resultUTF8.append(._space)
    }

    guard let close = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isRightSquareBracket
    ) else {
      return nil
    }
    resultUTF8.append(close)

    return (String(decoding: resultUTF8, as: UTF8.self), currentIndex)
  }
}

public struct MIMEDomainLiteralParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = MIMEDomainLiteral

  public typealias Configuration = MIMEAddressSpecification.ParserConfiguration

  let input: Input
  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEDomainLiteral, endIndex: Input.Index)? {
    typealias __CFWSParser = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>

    var currentIndex = input.startIndex

    let leadingComments: [MIMEComment]? = __CFWSParser.parse(
      input,
      from: &currentIndex,
      configuration: configuration.cfwsParserConfiguration
    ) ?? nil

    guard let core = _MIMEDomainLiteralCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) else {
      return nil
    }

    let trailingComments: [MIMEComment]? = __CFWSParser.parse(
      input,
      from: &currentIndex,
      configuration: configuration.cfwsParserConfiguration
    ) ?? nil

    return (
      MIMEDomainLiteral(
        leadingComments: leadingComments,
        _validatedText: core,
        trailingComments: trailingComments
      ),
      currentIndex
    )
  }
}

extension MIMEDomainLiteral: _InitializableWithParser {
  @inlinable
  public init?<S>(
    parsing string: S,
    configuration: MIMEAddressSpecification.ParserConfiguration? = nil
  ) where S: StringProtocol {
    self.init(string, parser: MIMEDomainLiteralParser<S>.self, configuration: configuration)
  }
}

extension MIMEAddressSpecification {
  public struct LocalPartParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
    public typealias Output = LocalPart

    public typealias Configuration = ParserConfiguration

    @usableFromInline let input: Input
    @usableFromInline let utf8: Input.UTF8View

    public var configuration: Configuration

    public init(input: Input, configuration: Configuration? = nil) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .default
    }

    public mutating func parse() -> (output: LocalPart, endIndex: Input.Index)? {
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

      var partialLocalPart: LocalPart? = nil
      if let dotAtomCore = _MIMEDotAtomCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        partialLocalPart = LocalPart(
          MIMEDotAtom(
            leadingComments: nil,
            _validatedText: dotAtomCore._string,
            trailingComments: nil
          )
        )
      } else if let qsCore = _MIMEQuotedStringCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        partialLocalPart = LocalPart(qsCore)
      }

      guard var localPart = partialLocalPart else {
        return nil
      }
      localPart.leadingComments = leadingComments
      if let trailingCFWS = __parseCFWS() {
        localPart.trailingComments = trailingCFWS
      }

      return (localPart, currentIndex)
    }
  }

  public struct DomainPortionParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
    public typealias Output = DomainPortion

    public typealias Configuration = ParserConfiguration

    @usableFromInline let input: Input
    @usableFromInline let utf8: Input.UTF8View

    public var configuration: Configuration

    public init(input: Input, configuration: Configuration? = nil) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .default
    }

    public mutating func parse() -> (output: DomainPortion, endIndex: Input.Index)? {
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

      var partialDomainPortion: DomainPortion? = nil
      if let dotAtomCore = _MIMEDotAtomCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        partialDomainPortion = DomainPortion(
          MIMEDotAtom(
            leadingComments: nil,
            _validatedText: dotAtomCore._string,
            trailingComments: nil
          )
        )
      } else if let literalCore = _MIMEDomainLiteralCoreParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        partialDomainPortion = DomainPortion(
          MIMEDomainLiteral(
            leadingComments: nil,
            _validatedText: literalCore,
            trailingComments: nil
          )
        )
      }

      guard var domainPortion = partialDomainPortion else {
        return nil
      }
      domainPortion.leadingComments = leadingComments
      if let trailingCFWS = __parseCFWS() {
        domainPortion.trailingComments = trailingCFWS
      }

      return (domainPortion, currentIndex)
    }
  }
}


public struct MIMEAddressSpecificationParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = MIMEAddressSpecification

  public typealias Configuration = MIMEAddressSpecification.ParserConfiguration

  @usableFromInline let input: Input
  @usableFromInline let utf8: Input.UTF8View
  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEAddressSpecification, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    guard let localPart = MIMEAddressSpecification.LocalPartParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: self.configuration
    ) else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isAtSign) else {
      return nil
    }

    guard let domainPortion = MIMEAddressSpecification.DomainPortionParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: self.configuration
    ) else {
      return nil
    }

    return (
      MIMEAddressSpecification(localPart: localPart, domainPortion: domainPortion),
      currentIndex
    )
  }
}

extension MIMEAddressSpecification: _InitializableWithParser {
  public init?<S>(
    parsing string: S,
    configuration: MIMEAddressSpecification.ParserConfiguration? = nil
  ) where S: StringProtocol {
    self.init(
      string,
      parser: MIMEAddressSpecificationParser<S>.self,
      configuration: configuration
    )
  }
}
