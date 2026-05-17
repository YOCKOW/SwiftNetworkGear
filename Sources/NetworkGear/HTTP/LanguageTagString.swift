/* *************************************************************************************************
 LanguageTagString.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A string that represents ["Language Tag"](https://datatracker.ietf.org/doc/html/rfc5646).
public struct LanguageTagString: Sendable {


  /// Represents `privateuse`.
  public struct PrivateUse: Sendable, CustomStringConvertible, Equatable, Hashable {
    private let _string: ASCIICaseInsensitiveString

    public var description: String { String(describing: _string) }

    fileprivate init(_ string: ASCIICaseInsensitiveString) {
      self._string = string
    }

    internal struct Parser<Input>: StringParser, _UTF8Parser
    where Input: StringProtocol, Input.SubSequence == Substring {
      typealias Output = PrivateUse

      let string: Input
      let utf8: Input.UTF8View

      init(input: Input) {
        self.string = input
        self.utf8 = input.utf8
      }

      mutating func parse() -> (output: PrivateUse, endIndex: Input.Index)? {
        var index = utf8.startIndex

        guard let _ = self.readCurrentCodeUnit(
          at: &index,
          ifAllowedCodeUnit: { $0 == 0x58 || $0 == 0x78 } // "X" or "x"
        ) else {
          return nil
        }

        func __consumeNextTag() -> Input.Index? {
          let startIndex = index
          guard let _ = self.readCurrentCodeUnit(
            at: &index,
            ifAllowedCodeUnit: { $0 == 0x2D } // "-"
          ) else {
            return nil
          }
          guard let _ = self.parseString(
            from: &index,
            minCount: 1,
            maxCount: 8,
            while: \._isAlphanumeric
          ) else {
            index = startIndex
            return nil
          }
          return index
        }

        guard let _ = __consumeNextTag() else { return nil }
        while let _ = __consumeNextTag() {}
        return (PrivateUse(ASCIICaseInsensitiveString(String(string[..<index]))), index)
      }
    } // PrivateUse.Parser

    public init?<S>(_ string: S) where S: StringProtocol, S.SubSequence == Substring {
      guard let parsedResult = Parser<S>.parse(string),
            parsedResult.endIndex == string.endIndex else {
        return nil
      }
      self = parsedResult.output
    }
  } // PrivateUse
}
