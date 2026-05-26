/* *************************************************************************************************
 HTTPHeaderFieldParameter.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

/// Key-value pairs for "HTTP Parameter Continuations".
///
/// Reference:
///   - [RFC 8187 §3.1](https://datatracker.ietf.org/doc/html/rfc8187#section-3.1)
public struct HTTPHeaderFieldParameter: Sendable {
  public struct ExtendedValue: Sendable, Equatable, CustomStringConvertible {
    /// String representation of "MIME Charset".
    public let stringEncodingDescription: String

    /// String representation of "Language Tag"
    public let languageTagDescription: LanguageTagString?

    /// Percent-encoded value.
    public let percentEncodedValue: PercentEncodedString

    public var description: String {
      return "\(stringEncodingDescription)'\(languageTagDescription?.description ?? "")'\(percentEncodedValue.encodedString)"
    }

    public var stringEncoding: String.Encoding? {
      #if compiler(>=6.3)
      if #available(macOS 26.4, iOS 26.4, *),
         let encoding = String.Encoding(ianaName: stringEncodingDescription) {
        return encoding
      }
      #endif
      return String.Encoding(ianaCharacterSetName: stringEncodingDescription)
    }

    public var locale: Locale? {
      return languageTagDescription?.locale
    }

    public var decodedValue: String? {
      if let stringEncoding = self.stringEncoding {
        return percentEncodedValue.decodedString(usingStringEncoding: stringEncoding)
      } else {
        return percentEncodedValue.decodedString
      }
    }

    @inlinable
    internal init(_validated: (
        stringEncodingDescription: String,
        languageTagDescription: LanguageTagString?,
        percentEncodedValue: PercentEncodedString
    )) {
      self.stringEncodingDescription = _validated.stringEncodingDescription
      self.languageTagDescription = _validated.languageTagDescription
      self.percentEncodedValue = _validated.percentEncodedValue
    }
  }
}

public struct ExtendedParameterValueParser<Input>: StringParser,
                                                   _UTF8Parser where Input: StringProtocol {
  public typealias Output = HTTPHeaderFieldParameter.ExtendedValue

  let string: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.string = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: HTTPHeaderFieldParameter.ExtendedValue, endIndex: Input.Index)? {
    var index = utf8.startIndex
    guard let stringEncodingDescription = self.parseString(
      from: &index,
      while: \._isAvailableInMIMECharsetInExtendedValue
    ) else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isApostrophe) else {
      return nil
    }

    var languageTagDescription: LanguageTagString? = nil
    if let langTagResult = LanguageTagStringParser<Input.SubSequence>.parse(string[index...]) {
      languageTagDescription = langTagResult.output
      index = langTagResult.endIndex
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isApostrophe) else {
      return nil
    }

    guard let percentEncodedString = self.parseString(
      from: &index,
      while: \._isAvailableInPercentEncodedContentInExtendedValue
    ) else {
      return nil
    }
    let percentEncodedValue = PercentEncodedString(encodedString: percentEncodedString._string)

    return (
      output: HTTPHeaderFieldParameter.ExtendedValue(_validated: (
        stringEncodingDescription: stringEncodingDescription._string,
        languageTagDescription: languageTagDescription,
        percentEncodedValue: percentEncodedValue
      )),
      endIndex: index
    )
  }
}

extension HTTPHeaderFieldParameter.ExtendedValue: _InitializableWithParser, LosslessStringConvertible {
  /// Creates an instance from `string`.
  public init?<S>(_ description: S) where S: StringProtocol {
    self.init(description, parser: ExtendedParameterValueParser<S>.self)
  }
}
