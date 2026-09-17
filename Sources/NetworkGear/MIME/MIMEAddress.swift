/* *************************************************************************************************
 MIMEAddress.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// Representation of `domain-literal` defined in [RFC 5322 §3.4.1](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4.1).
public struct MIMEDomainLiteral: Sendable, _SandwichedByOptionalCFWS {
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
public struct MIMEAddressSpecification: Sendable, _SandwichedByOptionalCFWS {
  /// Representation of `local-part` defined in [RFC 5322 §3.4.1](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4.1).
  public struct LocalPart: Sendable, _SandwichedByOptionalCFWS {
    fileprivate enum _Entity: Sendable, _EitherMappable {
      case dotAtom(MIMEDotAtom)
      case quotedString(MIMEQuotedString)

      typealias _Left = MIMEDotAtom
      typealias _Right = MIMEQuotedString

      init(_ dotAtom: MIMEDotAtom) {
        self = .dotAtom(dotAtom)
      }

      init(_ quotedString: MIMEQuotedString) {
        self = .quotedString(quotedString)
      }
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

    public internal(set) var leadingComments: [MIMEComment]? {
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


    public internal(set) var trailingComments: [MIMEComment]? {
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

    fileprivate init(_entity entity: _Entity) {
      self._entity = entity
    }

    public init(_ dotAtom: MIMEDotAtom) {
      self.init(_entity: .dotAtom(dotAtom))
    }

    public init(_ quotedString: MIMEQuotedString) {
      self.init(_entity: .quotedString(quotedString))
    }
  }

  /// Representation of `domain` defined in [RFC 5322 §3.4.1](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4.1).
  public struct DomainPortion: Sendable, _SandwichedByOptionalCFWS {
    fileprivate enum _Entity: Sendable, _EitherMappable {
      case dotAtom(MIMEDotAtom)
      case domainLiteral(MIMEDomainLiteral)

      typealias _Left = MIMEDotAtom
      typealias _Right = MIMEDomainLiteral

      init(_ dotAtom: MIMEDotAtom) {
        self = .dotAtom(dotAtom)
      }

      init(_ literal: MIMEDomainLiteral) {
        self = .domainLiteral(literal)
      }
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

    public internal(set) var leadingComments: [MIMEComment]? {
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


    public internal(set) var trailingComments: [MIMEComment]? {
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

    fileprivate init(_entity entity: _Entity) {
      self._entity = entity
    }

    public init(_ dotAtom: MIMEDotAtom) {
      self.init(_entity: .dotAtom(dotAtom))
    }

    public init(_ domainLiteral: MIMEDomainLiteral) {
      self.init(_entity: .domainLiteral(domainLiteral))
    }
  }

  public internal(set) var localPart: LocalPart

  public internal(set) var domainPortion: DomainPortion

  internal var leadingComments: [MIMEComment]? {
    get {
      self.localPart.leadingComments
    }
    set {
      self.localPart.leadingComments = newValue
    }
  }

  internal var trailingComments: [MIMEComment]? {
    get {
      self.domainPortion.trailingComments
    }
    set {
      self.domainPortion.trailingComments = newValue
    }
  }

  public init(localPart: LocalPart, domainPortion: DomainPortion) {
    self.localPart = localPart
    self.domainPortion = domainPortion
  }
}

extension MIMEAddressSpecification {
  public struct ParserConfiguration: Sendable, _SandwichedByOptionalCFWSParserConfiguration {
    public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

    public init(
      cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default
    ) {
      self.cfwsParserConfiguration = cfwsParserConfiguration
    }

    public static let `default`: ParserConfiguration = .init()
  }
}

public struct MIMEDomainLiteralParser<Input>: StringParser, _SandwichedByOptionalCFWSParser
where Input: StringProtocol {
  public typealias Output = MIMEDomainLiteral

  public typealias Configuration = MIMEAddressSpecification.ParserConfiguration

  typealias CoreParserInput = Input.SubSequence
  struct CoreParser: StringParser, _UTF8Parser {
    let input: CoreParserInput
    let utf8: CoreParserInput.UTF8View
    var configuration: Configuration

    init(input: CoreParserInput, configuration: Configuration?) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .default
    }

    mutating func parse() -> (output: Output, endIndex: CoreParserInput.Index)? {
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

      return (
        MIMEDomainLiteral(
          leadingComments: nil,
          _validatedText: String(decoding: resultUTF8, as: UTF8.self),
          trailingComments: nil
        ),
        currentIndex
      )
    }
  } // /CoreParser

  @usableFromInline let input: Input
  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEDomainLiteral, endIndex: Input.Index)? {
    return self._parseWhole()
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
  public struct LocalPartParser<Input>: StringParser, _SandwichedByOptionalCFWSParser where Input: StringProtocol {
    public typealias Output = LocalPart

    public typealias Configuration = ParserConfiguration

    typealias CoreParserInput = Input.SubSequence
    struct CoreParser: StringParser {
      let input: CoreParserInput
      var configuration: Configuration

      init(input: CoreParserInput, configuration: Configuration?) {
        self.input = input
        self.configuration = configuration ?? .default
      }

      mutating func parse() -> (output: Output, endIndex: CoreParserInput.Index)? {
        var parser = _EitherParser<
          CoreParserInput,
          MIMEDotAtomParser<CoreParserInput>.CoreParser,
          MIMEQuotedStringParser<CoreParserInput>.CoreParser
        >(
          input: input,
          configuration: .init(
            leftParserConfiguration: .init(cfwsParserConfiguration: configuration.cfwsParserConfiguration),
            rightParserConfiguration: .init(cfwsParserConfiguration: configuration.cfwsParserConfiguration)
          )
        )
        guard let (either, endIndex) = parser.parse() else {
          return nil
        }
        return (
          LocalPart(_entity: either.map(type: LocalPart._Entity.self)),
          endIndex
        )
      }
    }

    @usableFromInline let input: Input

    public var configuration: Configuration

    @inlinable
    public var cfwsParserConfiguration: CFWSParserConfiguration {
      return self.configuration.cfwsParserConfiguration
    }

    public init(input: Input, configuration: Configuration? = nil) {
      self.input = input
      self.configuration = configuration ?? .default
    }

    public mutating func parse() -> (output: LocalPart, endIndex: Input.Index)? {
      return _parseWhole()
    }
  }

  public struct DomainPortionParser<Input>: StringParser, _SandwichedByOptionalCFWSParser where Input: StringProtocol {
    public typealias Output = DomainPortion

    public typealias Configuration = ParserConfiguration

    typealias CoreParserInput = Input.SubSequence
    struct CoreParser: StringParser {
      let input: CoreParserInput
      var configuration: Configuration

      init(input: CoreParserInput, configuration: Configuration?) {
        self.input = input
        self.configuration = configuration ?? .default
      }

      mutating func parse() -> (output: Output, endIndex: CoreParserInput.Index)? {
        var parser = _EitherParser<
          CoreParserInput,
          MIMEDotAtomParser<CoreParserInput>.CoreParser,
          MIMEDomainLiteralParser<CoreParserInput>.CoreParser
        >(
          input: input,
          configuration: .init(
            leftParserConfiguration: .init(cfwsParserConfiguration: configuration.cfwsParserConfiguration),
            rightParserConfiguration: .init(cfwsParserConfiguration: configuration.cfwsParserConfiguration)
          )
        )
        guard let (either, endIndex) = parser.parse() else {
          return nil
        }
        return (
          DomainPortion(_entity: either.map(type: DomainPortion._Entity.self)),
          endIndex
        )
      }
    }

    @usableFromInline let input: Input
    @usableFromInline let utf8: Input.UTF8View

    public var configuration: Configuration

    @inlinable
    public var cfwsParserConfiguration: CFWSParserConfiguration {
      get {
        return configuration.cfwsParserConfiguration
      }
      set {
        self.configuration.cfwsParserConfiguration = newValue
      }
    }

    public init(input: Input, configuration: Configuration? = nil) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .default
    }

    public mutating func parse() -> (output: DomainPortion, endIndex: Input.Index)? {
      return _parseWhole()
    }
  }
}


public struct MIMEAddressSpecificationParser<Input>: StringParser, _SandwichedByOptionalCFWSParser
where Input: StringProtocol {
  public typealias Output = MIMEAddressSpecification

  public typealias Configuration = MIMEAddressSpecification.ParserConfiguration

  typealias CoreParserInput = Input.SubSequence
  struct CoreParser: StringParser, _UTF8Parser {
    let input: CoreParserInput
    var configuration: Configuration
    var cfwsParserConfiguration: CFWSParserConfiguration {
      return configuration.cfwsParserConfiguration
    }

    init(input: CoreParserInput, configuration: Configuration?) {
      self.input = input
      self.configuration = configuration ?? .default
    }

    mutating func parse() -> (output: Output, endIndex: Input.Index)? {
      typealias _PartialLocalPartParser = MIMEAddressSpecification.LocalPartParser<CoreParserInput>.PostLeadingCFWSParser
      guard let (partialLocalPart, localPartEndIndex) = _PartialLocalPartParser.parse(
        input,
        configuration: .init(cfwsParserConfiguration: cfwsParserConfiguration)
      ) else {
        return nil
      }

      var currentIndex = localPartEndIndex
      guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isAtSign) else {
        return nil
      }

      let leadingCommentsOfDomainPortion: [MIMEComment]? = CFWSParser<CoreParserInput.SubSequence>.parse(
        input,
        from: &currentIndex,
        configuration: cfwsParserConfiguration
      ) ?? nil
      typealias _PartialDomainPortionParser = MIMEAddressSpecification.DomainPortionParser<CoreParserInput.SubSequence>.CoreParser
      guard var partialDomainPortion = _PartialDomainPortionParser.parse(
        input,
        from: &currentIndex,
        configuration: .init(cfwsParserConfiguration: cfwsParserConfiguration)
      ) else {
        return nil
      }
      partialDomainPortion.leadingComments = leadingCommentsOfDomainPortion

      return (
        MIMEAddressSpecification(localPart: partialLocalPart, domainPortion: partialDomainPortion),
        currentIndex
      )
    }
  }

  @usableFromInline let input: Input
  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEAddressSpecification, endIndex: Input.Index)? {
    return _parseWhole()
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

/// Representation of `display-name` defined in [RFC 5322 §3.4](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4).
public struct MIMEDisplayName: Sendable, _StartsWithOptionalCFWS {
  @usableFromInline internal var _entity: MIMEPhrase

  public internal(set) var leadingComments: [MIMEComment]? {
    get {
      return self._entity.leadingComments
    }
    set {
      self._entity.leadingComments = newValue
    }
  }

  @inlinable
  public init(_ phrase: MIMEPhrase) {
    self._entity = phrase
  }
}

public struct MIMEDisplayNameParserConfiguration: Sendable, _StartsWithOptionalCFWSParserConfiguration {
  internal var _phraseParserConfiguration: MIMEPhraseParserConfiguration

  public var cfwsParserConfiguration: CFWSParserConfiguration {
    get {
      return _phraseParserConfiguration.cfwsParserConfiguration
    }
    set {
      _phraseParserConfiguration.cfwsParserConfiguration = newValue
    }
  }

  public init(cfwsParserConfiguration: CFWSParserConfiguration? = nil) {
    self._phraseParserConfiguration = cfwsParserConfiguration.map(MIMEPhraseParserConfiguration.init) ?? .default
  }

  public static let `default`: MIMEDisplayNameParserConfiguration = .init()
}

public struct MIMEDisplayNameParser<Input>: StringParser, _StartsWithOptionalCFWSParser where Input: StringProtocol {
  public typealias Output = MIMEDisplayName
  public typealias Configuration = MIMEDisplayNameParserConfiguration

  typealias PostLeadingCFWSInput = Input.SubSequence
  struct PostLeadingCFWSParser: StringParser {
    let input: PostLeadingCFWSInput
    var configuration: Configuration

    init(input: PostLeadingCFWSInput, configuration: Configuration?) {
      self.input = input
      self.configuration = configuration ?? .default
    }

    mutating func parse() -> (output: Output, endIndex: PostLeadingCFWSInput.Index)? {
      guard let (partialPhrase, endIndex) = MIMEPhraseParser<PostLeadingCFWSInput>.PostLeadingCFWSParser.parse(
        input,
        configuration: configuration._phraseParserConfiguration
      ) else {
        return nil
      }
      return (MIMEDisplayName(partialPhrase), endIndex)
    }
  }

  @usableFromInline let input: Input
  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEDisplayName, endIndex: Input.Index)? {
    return _parseWhole()
  }
}

/// Representation of `angle-addr` defined in [RFC 5322 §3.4](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4).
public struct MIMEAngleBracketEnclosedAddress: Sendable, _SandwichedByOptionalCFWS {
  public internal(set) var leadingComments: [MIMEComment]?

  public var addressSpecification: MIMEAddressSpecification

  public internal(set) var trailingComments: [MIMEComment]?

  internal init(
    leadingComments: [MIMEComment]?,
    addressSpecification: MIMEAddressSpecification,
    trailingComments: [MIMEComment]?
  ) {
    self.leadingComments = leadingComments
    self.addressSpecification = addressSpecification
    self.trailingComments = trailingComments
  }
}

public struct MIMEAngleBracketEnclosedAddressParserConfiguration: Sendable, _SandwichedByOptionalCFWSParserConfiguration {
  public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

  public init(
    cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default
  ) {
    self.cfwsParserConfiguration = cfwsParserConfiguration
  }

  public static let `default`: MIMEAngleBracketEnclosedAddressParserConfiguration = .init()
}

public struct MIMEAngleBracketEnclosedAddressParser<Input>: StringParser, _SandwichedByOptionalCFWSParser
where Input: StringProtocol {
  public typealias Output = MIMEAngleBracketEnclosedAddress

  public typealias Configuration = MIMEAngleBracketEnclosedAddressParserConfiguration

  struct CoreParser: StringParser, _UTF8Parser {
    let input: Input.SubSequence
    let utf8: Input.SubSequence.UTF8View
    var configuration: Configuration

    init(input: Input.SubSequence, configuration: Configuration? = nil) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .default
    }

    mutating func parse() -> (output: Output, endIndex: Input.SubSequence.Index)? {
      var currentIndex = self.utf8.startIndex

      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isLessThanSign
      ) else {
        return nil
      }

      guard let addrSpec = MIMEAddressSpecificationParser<Input.SubSequence.SubSequence>.parse(
        input,
        from: &currentIndex,
      ) else {
        return nil
      }

      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isGreaterThanSign
      ) else {
        return nil
      }

      return (
        MIMEAngleBracketEnclosedAddress(
          leadingComments: nil,
          addressSpecification: addrSpec,
          trailingComments: nil
        ),
        currentIndex
      )
    }
  }

  @usableFromInline let input: Input
  public var configuration: Configuration

  @inlinable
  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMEAngleBracketEnclosedAddress, endIndex: Input.Index)? {
    return self._parseWhole()
  }
}

extension MIMEAngleBracketEnclosedAddress: _InitializableWithParser {
  public init?<S>(
    parsing string: S,
    configuration: MIMEAngleBracketEnclosedAddressParserConfiguration? = nil
  ) where S: StringProtocol {
    self.init(
      string,
      parser: MIMEAngleBracketEnclosedAddressParser<S>.self,
      configuration: configuration
    )
  }
}

/// Representation of `name-addr` defined in [RFC 5322 §3.4](https://datatracker.ietf.org/doc/html/rfc5322#section-3.4).
public struct MIMENameAddress: Sendable, _StartsWithOptionalCFWS {
  public var displayName: MIMEDisplayName?

  public var address: MIMEAngleBracketEnclosedAddress

  public internal(set) var leadingComments: [MIMEComment]? {
    get {
      return displayName?.leadingComments ?? address.leadingComments
    }
    set {
      if var displayName = self.displayName {
        displayName.leadingComments = newValue
        self.displayName = displayName
      } else {
        self.address.leadingComments = newValue
      }
    }
  }

  public init(displayName: MIMEDisplayName?, address: MIMEAngleBracketEnclosedAddress) {
    self.displayName = displayName
    self.address = address
  }
}

public struct MIMENameAddressParserConfiguration: Sendable, _StartsWithOptionalCFWSParserConfiguration {
  public var cfwsParserConfiguration: CFWSParserConfiguration

  public init(cfwsParserConfiguration: CFWSParserConfiguration = .default) {
    self.cfwsParserConfiguration = cfwsParserConfiguration
  }

  public static let `default`: MIMENameAddressParserConfiguration = .init()
}

public struct MIMENameAddressParser<Input>: StringParser, _StartsWithOptionalCFWSParser
where Input: StringProtocol {
  public typealias Output = MIMENameAddress

  public typealias Configuration = MIMENameAddressParserConfiguration

  typealias PostLeadingCFWSInput = Input.SubSequence
  struct PostLeadingCFWSParser: StringParser {
    typealias Input = PostLeadingCFWSInput

    let input: PostLeadingCFWSInput

    var configuration: Configuration

    var cfwsParserConfiguration: CFWSParserConfiguration {
      get { configuration.cfwsParserConfiguration }
      set { configuration.cfwsParserConfiguration = newValue }
    }

    init(input: PostLeadingCFWSInput, configuration: Configuration?) {
      self.input = input
      self.configuration = configuration ?? .default
    }

    mutating public func parse() -> (output: Output, endIndex: PostLeadingCFWSInput.Index)? {
      var eitherParser = _EitherOfTypesStartingWithOptionalCFWSParser<
        PostLeadingCFWSInput,
        MIMEDisplayNameParser<PostLeadingCFWSInput>,
        MIMEAngleBracketEnclosedAddressParser<PostLeadingCFWSInput>
      >(
        input: input,
        configuration: .init(
          leftParserConfiguration: .init(cfwsParserConfiguration: cfwsParserConfiguration),
          rightParserConfiguration: .init(cfwsParserConfiguration: cfwsParserConfiguration)
        )
      )
      guard let eitherResult = eitherParser.parse() else {
        return nil
      }
      switch eitherResult.output {
      case .left(let displayName):
        var angleAddrParser = MIMEAngleBracketEnclosedAddressParser<PostLeadingCFWSInput.SubSequence>(
          input: input[eitherResult.endIndex...],
          configuration: .init(cfwsParserConfiguration: cfwsParserConfiguration)
        )
        guard let angleAddrResult = angleAddrParser.parse() else {
          return nil
        }
        return (
          MIMENameAddress(displayName: displayName, address: angleAddrResult.output),
          angleAddrResult.endIndex
        )
      case .right(let angleAddr):
        return (
          MIMENameAddress(displayName: nil, address: angleAddr),
          eitherResult.endIndex
        )
      }
    }
  }

  @usableFromInline let input: Input

  public var configuration: Configuration

  public var cfwsParserConfiguration: CFWSParserConfiguration {
    get { configuration.cfwsParserConfiguration }
    set { configuration.cfwsParserConfiguration = newValue }
  }

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .default
  }

  public mutating func parse() -> (output: MIMENameAddress, endIndex: Input.Index)? {
    return self._parseWhole()
  }
}

extension MIMENameAddress: _InitializableWithParser {
  public init?<S>(
    parsing string: S,
    configuration: MIMENameAddressParserConfiguration? = nil
  ) where S: StringProtocol {
    self.init(string, parser: MIMENameAddressParser<S>.self, configuration: configuration)
  }
}
