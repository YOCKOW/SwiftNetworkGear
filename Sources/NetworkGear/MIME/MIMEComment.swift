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

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: MIMEComment, endIndex: Input.Index)? {
    // Implementation Note:
    //   ccontent        =   ctext / quoted-pair / comment
    //   comment         =   "(" *([FWS] ccontent) [FWS] ")"

    var comment = MIMEComment()

    var textBuffer = Data()
    func __flushText() {
      if textBuffer.isEmpty {
        return
      }
      comment.append(String(decoding: textBuffer, as: UTF8.self))
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
      _ = FoldingWhitespaceParser.parse(input, from: &currentIndex)

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

      __flushText()

      if let nestedComment = MIMECommentParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        comment.append(nestedComment)
        continue
      }

      _ = FoldingWhitespaceParser.parse(input, from: &currentIndex)
      break
    }

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
  public init?<S>(parsing string: S) where S: StringProtocol {
    self.init(string, parser: MIMECommentParser<S>.self)
  }
}


/// A parser to parse `CFWS` defined in [RFC 5322 §3.2.2](https://datatracker.ietf.org/doc/html/rfc5322#section-3.2.2).
public struct MIMECommentCoexistableFoldingWhitespaceParser<Input>: StringParser
where Input: StringProtocol {
  public typealias Output = Array<MIMEComment>?

  let input: Input

  public init(input: Input) {
    self.input = input
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
      if let comment = MIMECommentParser<Input.SubSequence>.parse(input, from: &currentIndex) {
        return .fwsAndComment(comment)
      }
      return .fws
    }

    guard let comment = MIMECommentParser<Input.SubSequence>.parse(input, from: &currentIndex) else {
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
