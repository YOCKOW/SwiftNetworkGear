/* *************************************************************************************************
 utils.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import NetworkGear
import Testing

let FWS = "\u{0D}\u{0A} "

extension MIMEComment.Content {
  static func text<S>(
    _ string: S,
    sourceLocation: SourceLocation = #_sourceLocation
  ) -> MIMEComment.Content where S: StringProtocol {
    return .text(try! #require(MIMECommentText(string), sourceLocation: sourceLocation))
  }
}
