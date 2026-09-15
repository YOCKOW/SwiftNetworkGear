/* *************************************************************************************************
 MIMEAtom.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `atom` defined in [RFC 5322 §3.2.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.3).
public struct MIMEAtom: Sendable, Equatable, _SandwichedByOptionalCFWS {
  public internal(set) var leadingComments: [MIMEComment]?

  public let text: String

  public internal(set) var trailingComments: [MIMEComment]?

  internal init(
    leadingComments: [MIMEComment]?,
    _validatedText text: String,
    trailingComments: [MIMEComment]?
  ) {
    assert(!text.isEmpty && text.utf8.allSatisfy(\._isAvailableInAtomText))
    self.leadingComments = leadingComments
    self.text = text
    self.trailingComments = trailingComments
  }
}

public struct MIMEAtomParserConfiguration: Sendable, _SandwichedByOptionalCFWSParserConfiguration {
  public var cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration

  @inlinable
  public init(cfwsParserConfiguration: MIMECommentCoexistableFoldingWhitespaceParserConfiguration = .default) {
    self.cfwsParserConfiguration = cfwsParserConfiguration
  }

  public static let `default`: MIMEAtomParserConfiguration = .init()
}

public struct MIMEAtomParser<Input>: StringParser,
                                     _UTF8Parser,
                                     _SandwichedByOptionalCFWSParser
where Input: StringProtocol {
  public typealias Output = MIMEAtom

  public typealias Configuration = MIMEAtomParserConfiguration

  internal struct CoreParser: StringParser, _UTF8Parser {
    typealias Output = MIMEAtom
    typealias Configuration = MIMEAtomParserConfiguration

    @usableFromInline let input: Input.SubSequence
    @usableFromInline let utf8: Input.SubSequence.UTF8View
    var configuration: Configuration

    init(input: Input.SubSequence, configuration: Configuration? = nil) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .default
    }

    mutating func parse() -> (output: MIMEAtom, endIndex: Input.SubSequence.Index)? {
      var currentIndex = self.utf8.startIndex
      guard let text = self.parseString(from: &currentIndex, while: \._isAvailableInAtomText) else {
        return nil
      }
      let partialAtom = MIMEAtom(
        leadingComments: nil,
        _validatedText: text._string,
        trailingComments: nil
      )
      return (partialAtom, currentIndex)
    }
  }

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
    return _parseWhole()
  }
}

extension MIMEAtom: _InitializableWithParser {
  public init?<S>(parsing string: S, configuration: MIMEAtomParser<S>.Configuration? = nil) where S: StringProtocol {
    self.init(string, parser: MIMEAtomParser<S>.self, configuration: configuration)
  }
}

/// Representation of `dot-atom` defined in [RFC 5322 §3.2.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.3).
public struct MIMEDotAtom: Sendable, _SandwichedByOptionalCFWS {
  public internal(set) var leadingComments: [MIMEComment]?

  /// `dot-atom-text`
  public let text: String

  @usableFromInline
  internal var _textContainsDot: Bool

  public internal(set) var trailingComments: [MIMEComment]?

  @usableFromInline
  internal init(
    leadingComments: [MIMEComment]?,
    _validatedText text: String,
    textContainsDot: Bool,
    trailingComments: [MIMEComment]?)
  {
    assert(
      !text.isEmpty &&
      text.utf8.first!._isAvailableInAtomText &&
      text.utf8.last!._isAvailableInAtomText &&
      text.utf8.allSatisfy({ $0._isAvailableInAtomText || $0._isPeriod })
    )
    assert(
      textContainsDot == text.utf8.contains(where: { $0._isPeriod })
    )
    self.leadingComments = leadingComments
    self.text = text
    self._textContainsDot = textContainsDot
    self.trailingComments = trailingComments
  }

  /// Creates an instance from `atom`.
  @inlinable
  public init(_ atom: MIMEAtom) {
    self.init(
      leadingComments: atom.leadingComments,
      _validatedText: atom.text,
      textContainsDot: false,
      trailingComments: atom.trailingComments
    )
  }
}

extension MIMEAtom {
  /// Creates an instance from `dot-atom` if possible.
  public init?(_ dotAtom: MIMEDotAtom) {
    if dotAtom._textContainsDot {
      return nil
    }
    self.init(
      leadingComments: dotAtom.leadingComments,
      _validatedText: dotAtom.text,
      trailingComments: dotAtom.trailingComments
    )
  }
}

public struct MIMEDotAtomParser<Input>: StringParser,
                                        _UTF8Parser,
                                        _SandwichedByOptionalCFWSParser
where Input: StringProtocol {
  public typealias Output = MIMEDotAtom

  public typealias Configuration = MIMEAtomParser<Input>.Configuration

  struct CoreParser: StringParser, _UTF8Parser {
    typealias Output = MIMEDotAtom
    typealias Configuration = MIMEAtomParserConfiguration

    @usableFromInline let input: Input.SubSequence
    @usableFromInline let utf8: Input.SubSequence.UTF8View
    var configuration: Configuration

    init(input: Input.SubSequence, configuration: Configuration? = nil) {
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

    @inlinable
    mutating func parse() -> (output: MIMEDotAtom, endIndex: Input.SubSequence.Index)? {
      var currentIndex = self.utf8.startIndex

      guard let _ = self.parseString(from: &currentIndex, while: \._isAvailableInAtomText) else {
        return nil
      }
      let atomEndIndex = currentIndex
      while self._parseDotAndAtext(from: &currentIndex) {}

      let text = self.input[..<currentIndex]
      let textContainsDot = atomEndIndex < currentIndex

      let partialDotAtom = MIMEDotAtom(
        leadingComments: nil,
        _validatedText: text._string,
        textContainsDot: textContainsDot,
        trailingComments: nil
      )

      return (partialDotAtom, currentIndex)
    }
  }

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

  public mutating func parse() -> (output: MIMEDotAtom, endIndex: Input.Index)? {
    return self._parseWhole()
  }
}

extension MIMEDotAtom: _InitializableWithParser {
  public init?<S>(parsing string: S, configuration: MIMEDotAtomParser<S>.Configuration? = nil) where S: StringProtocol {
    self.init(string, parser: MIMEDotAtomParser<S>.self, configuration: configuration)
  }
}
