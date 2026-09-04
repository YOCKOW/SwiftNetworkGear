/* *************************************************************************************************
 MIMEComment.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// A type for representation of `comment` defined in [RFC 5322 §3.2.2](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.2).
public struct MIMEComment: Sendable, Equatable {
  public enum Content: Sendable, Equatable {
    /// Text
    case text(String)

    /// Nested comment
    case comment(MIMEComment)
  }

  public private(set) var contents: [Content]

  public init<Contents>(_ contents: Contents) where Contents: Sequence, Contents.Element == Content {
    self.contents = Array<Content>(contents)
  }

  public init() {
    self.init([])
  }

  public mutating func append(_ content: Content) {
    switch (self.contents.last, content) {
    case (.text(let lastText), .text(let newText)):
      self.contents.removeLast()
      self.contents.append(.text(lastText + newText))
    default:
      self.contents.append(content)
    }
  }

  @inlinable
  public mutating func append<S>(_ string: S) where S: StringProtocol {
    self.append(.text(string._string))
  }

  @inlinable
  public mutating func append(_ nestedComment: MIMEComment) {
    self.append(.comment(nestedComment))
  }
}

extension MIMEComment.Content {
  public static func comment<Contents>(
    _ contents: Contents
  ) -> MIMEComment.Content where Contents: Sequence, Contents.Element == MIMEComment.Content {
    return .comment(MIMEComment(contents))
  }
}

/// A parser to parse a comment in MIME header
public struct MIMECommentParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = MIMEComment

  public struct Configuration: Sendable {
    public let ignoreLeadingWhitespaces: Bool
    public let ignoreTrailingWhitespaces: Bool

    public init(
      ignoreLeadingWhitespaces: Bool = true,
      ignoreTrailingWhitespaces: Bool = true
    ) {
      self.ignoreLeadingWhitespaces = ignoreLeadingWhitespaces
      self.ignoreTrailingWhitespaces = ignoreTrailingWhitespaces
    }
  }

  let input: Input
  let utf8: Input.UTF8View

  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration ?? .init()
  }

  public mutating func parse() -> (output: MIMEComment, endIndex: Input.Index)? {
    // Implementation Note:
    //   ccontent        =   ctext / quoted-pair / comment
    //   comment         =   "(" *([FWS] ccontent) [FWS] ")"

    var comment = MIMEComment()

    var textBuffer = Data()
    func __flushText(removeTrailingWhitespaces: Bool) {
      if textBuffer.isEmpty {
        return
      }
      if removeTrailingWhitespaces {
        if let lastIndex = textBuffer.lastIndex(where: { !$0._isMIMEWhitespace }) {
          comment.append(String(decoding: textBuffer[...lastIndex], as: UTF8.self))
        }
      } else {
        comment.append(String(decoding: textBuffer, as: UTF8.self))
      }
      textBuffer.removeAll(keepingCapacity: true)
    }

    var currentIndex = self.utf8.startIndex

    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isLeftParenthesis
    ) else {
      return nil
    }

    while currentIndex < self.utf8.endIndex {
      if let _ = FoldingWhitespaceParser.parse(input, from: &currentIndex) {
        if !textBuffer.isEmpty || !configuration.ignoreLeadingWhitespaces {
          textBuffer.append(._space)
        }
      }

      if let ctext = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isAvailableInMIMEComment
      ) {
        textBuffer.append(ctext)
        continue
      } else if let escaped = self.parseMIMEQuotedPair(from: &currentIndex) {
        textBuffer.append(escaped)
        continue
      }

      if let nestedComment = MIMECommentParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        __flushText(removeTrailingWhitespaces: configuration.ignoreTrailingWhitespaces)
        comment.append(nestedComment)
        continue
      }

      if let _ = FoldingWhitespaceParser.parse(input, from: &currentIndex) {
        if !textBuffer.isEmpty || !configuration.ignoreTrailingWhitespaces {
          textBuffer.append(._space)
        }
      }
      break
    }

    __flushText(removeTrailingWhitespaces: configuration.ignoreTrailingWhitespaces)

    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isRightParenthesis
    ) else {
      return nil
    }

    return (comment, currentIndex)
  }
}


extension MIMEComment: _InitializableWithParser {
  public init?<S>(parsing string: S, configuration: MIMECommentParser<S>.Configuration? = nil) where S: StringProtocol {
    self.init(string, parser: MIMECommentParser<S>.self, configuration: configuration)
  }
}


/// A parser to parse `CFWS` defined in [RFC 5322 §3.2.2](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.2).
public struct MIMECommentCoexistableFoldingWhitespaceParser<Input>: StringParser
where Input: StringProtocol {
  public typealias Output = Array<MIMEComment>?

  public struct Configuration: Sendable {
    public var commentParsingConfiguration: MIMECommentParser<Input.SubSequence>.Configuration

    public init(commentParsingConfiguration: MIMECommentParser<Input.SubSequence>.Configuration = .init()) {
      self.commentParsingConfiguration = commentParsingConfiguration
    }
  }

  let input: Input

  public var configuration: Configuration

  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.configuration = configuration ?? .init()
  }

  private enum _Element {
    case fws
    case fwsAndComment(MIMEComment)
    case comment(MIMEComment)

    var comment: MIMEComment? {
      switch self {
      case .fws:
        return nil
      case .fwsAndComment(let comment), .comment(let comment):
        return comment
      }
    }
  }

  private func _parseElement(from currentIndex: inout Input.Index) -> _Element? {
    if let _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex) {
      if let comment = MIMECommentParser<Input.SubSequence>.parse(
        input,
        from: &currentIndex,
        configuration: configuration.commentParsingConfiguration
      ) {
        return .fwsAndComment(comment)
      }
      return .fws
    }

    guard let comment = MIMECommentParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: configuration.commentParsingConfiguration
    ) else {
      return nil
    }
    return .comment(comment)
  }

  public mutating func parse() -> (output: Array<MIMEComment>?, endIndex: Input.Index)? {
    var currentIndex = self.input.startIndex

    // Implementation Note:
    //   CFWS = (1*([FWS] comment) [FWS]) / FWS

    guard let firstElement = self._parseElement(from: &currentIndex) else {
      return nil
    }

    guard let firstComment = firstElement.comment else {
      return (output: nil, endIndex: currentIndex)
    }

    var comments: [MIMEComment] = [firstComment]
    while let element = self._parseElement(from: &currentIndex) {
      guard let comment = element.comment else {
        // `FWS` after `comment`.
        break
      }
      comments.append(comment)
    }
    return (comments, currentIndex)
  }
}
