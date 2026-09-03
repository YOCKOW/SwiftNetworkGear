/* *************************************************************************************************
 MIMEAtom.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `atom` defined in [RFC 5322 §3.2.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.3).
public struct MIMEAtom: Sendable {
  public let leadingComments: [MIMEComment]?

  public let text: String

  public let trailingComments: [MIMEComment]?

  fileprivate init(
    leadingComments: [MIMEComment]?,
    _validatedText text: String,
    trailingComments: [MIMEComment]?) {
    self.leadingComments = leadingComments
    self.text = text
    self.trailingComments = trailingComments
  }
}

public struct MIMEAtomParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = MIMEAtom

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: MIMEAtom, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    var leadingComments: [MIMEComment]? = nil
    if let leadingCFWS = MIMECommentCoexistableFoldingWhitespaceParser.parse(input, from: &currentIndex) {
      leadingComments = leadingCFWS
    }

    guard let text = self.parseString(from: &currentIndex, while: \._isAvailableInAtomText) else {
      return nil
    }

    var trailingComments: [MIMEComment]? = nil
    if let trailingCFWS = MIMECommentCoexistableFoldingWhitespaceParser.parse(input, from: &currentIndex) {
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
  public init?<S>(parsing string: S) where S: StringProtocol {
    self.init(string, parser: MIMEAtomParser<S>.self)
  }
}

/// Representation of `dot-atom` defined in [RFC 5322 §3.2.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.3).
public struct MIMEDotAtom: Sendable {
  public let leadingComments: [MIMEComment]?

  /// `dot-atom-text`
  public let text: String

  public let trailingComments: [MIMEComment]?

  fileprivate init(
    leadingComments: [MIMEComment]?,
    _validatedText text: String,
    trailingComments: [MIMEComment]?) {
    self.leadingComments = leadingComments
    self.text = text
    self.trailingComments = trailingComments
  }
}

public struct MIMEDotAtomParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = MIMEDotAtom

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
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

  public mutating func parse() -> (output: MIMEDotAtom, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    var leadingComments: [MIMEComment]? = nil
    if let leadingCFWS = MIMECommentCoexistableFoldingWhitespaceParser.parse(input, from: &currentIndex) {
      leadingComments = leadingCFWS
    }

    let textStartIndex = currentIndex
    guard let _ = self.parseString(from: &currentIndex, while: \._isAvailableInAtomText) else {
      return nil
    }
    while self._parseDotAndAtext(from: &currentIndex) {}
    let textEndIndex = currentIndex


    var trailingComments: [MIMEComment]? = nil
    if let trailingCFWS = MIMECommentCoexistableFoldingWhitespaceParser.parse(input, from: &currentIndex) {
      trailingComments = trailingCFWS
    }

    return (
      MIMEDotAtom(
        leadingComments: leadingComments,
        _validatedText: input[textStartIndex..<textEndIndex]._string,
        trailingComments: trailingComments
      ),
      currentIndex
    )
  }
}

extension MIMEDotAtom: _InitializableWithParser {
  public init?<S>(parsing string: S) where S: StringProtocol {
    self.init(string, parser: MIMEDotAtomParser<S>.self)
  }
}
