/* *************************************************************************************************
 ContentDisposition.swift
   © 2017-2019,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import yExtensions
import Foundation

/// Represents "Content-Disposition"
public struct ContentDisposition: Sendable {
  @available(*, deprecated, renamed: "DispositionType")
  public typealias Value = ContentDispositionValue

  public typealias DispositionType = ContentDispositionValue

  @available(*, deprecated)
  public typealias ParameterKey = ContentDispositionParameterKey

  /// A [Disposition Type](https://datatracker.ietf.org/doc/html/rfc6266#section-4.2).
  public var type: DispositionType

  @available(*, deprecated, renamed: "type")
  public var value: Value { type }

  public private(set) var parameterList: HTTPHeaderFieldParameterList?

  @available(*, deprecated, renamed: "parameterList")
  public var parameters: [ParameterKey:String]? {
    get {
      return parameterList?.reduce(into: [:]) {
        $0[ParameterKey(rawValue: $1.nameDescription)] = $1.valueDescription
      }
    }
    set {
      guard let newParameters = newValue else {
        parameterList = nil
        return
      }
      var list = HTTPHeaderFieldParameterList()
      for (key, valueString) in newParameters {
        let name = key.rawValue
        guard let (paramName, paramNameEndIndex) = _HTTPHeaderFieldParameterNameParser.parse(name),
              paramNameEndIndex == name.endIndex else {
          continue
        }
        switch paramName {
        case .regular(let regularName):
          guard let (value, valueEndIndex) = HTTPHeaderFieldParameterValueParser.parse(valueString),
                valueEndIndex == valueString.endIndex else {
            continue
          }
          list.append(.regular(name: regularName, value: value))
        case .extended(let extendedName):
          guard let (value, valueEndIndex) = ExtendedParameterValueParser.parse(valueString),
                valueEndIndex == valueString.endIndex else {
            continue
          }
          list.append(.extended(name: extendedName, value: value))
        }
      }
      self.parameterList = list
    }
  }

  /// A value for "filename" parameter.
  public var filename: String? {
    if let filename = parameterList?.combinedValue(for: "filename") {
      return filename
    }
    return parameterList?["filename"]?.value
  }

  /// Creates an insatance with the given `type` and `parameterList`.
  public init(type: DispositionType, parameterList: HTTPHeaderFieldParameterList? = nil) {
    self.type = type
    self.parameterList = parameterList
  }

  @available(*, deprecated)
  public init(type: DispositionType, parameters: [ParameterKey: String]?) {
    self.type = type
    self.parameterList = nil
    self.parameters = parameters
  }

  @available(*, deprecated, renamed: "init(type:parameters:)")
  public init(value: Value, parameters: [ParameterKey: String]? = nil) {
    self.init(type: value, parameters: parameters)
  }
}

extension ContentDisposition: Equatable, Hashable {
  public static func ==(lhs:ContentDisposition, rhs:ContentDisposition) -> Bool {
    return (
      lhs.type == rhs.type &&
      lhs.parameterList?._groupedParameters.nonSectioned == rhs.parameterList?._groupedParameters.nonSectioned &&
      lhs.parameterList?._groupedParameters.sectioned == rhs.parameterList?._groupedParameters.sectioned
    )
  }
  
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self.type)
    hasher.combine(self.parameterList?._groupedParameters.nonSectioned)
    hasher.combine(self.parameterList?._groupedParameters.sectioned)
  }
}

extension ContentDisposition: CustomStringConvertible {
  /// Description for the content disposition.
  /// e.g.) attachment; filename="filename.jpg"
  public var description: String {
    var desc = self.type.rawValue
    if let parameters = self.parameterList {
      for parameter in parameters {
        desc += "; \(parameter.description)"
      }
    }
    return desc
  }
}

extension ContentDisposition {
  public enum MIMESafeDescriptionError: Error {
    case dispositionTypeTooLong
    case failedToConvertParameterListForMIME
    case unexpectedParameterDescription(HTTPHeaderFieldParameter)
  }

  public var mimeSafeDescription: String {
    get throws(MIMESafeDescriptionError) {
      let nPerLine = 76
      var remainingUTF8CountInCurrentLine = nPerLine

      var descData = Data()

      func __append(_ byte: UTF8.CodeUnit) {
        assert(remainingUTF8CountInCurrentLine > 0)
        descData.append(byte)
        remainingUTF8CountInCurrentLine -= 1
      }

      func __appendCRLFSP() {
        if descData.last == ._space {
          descData = descData.dropLast()
          assert(descData.last == ._semicolon)
        }
        descData.append(._carriageReturn)
        descData.append(._lineFeed)
        descData.append(._space)
        remainingUTF8CountInCurrentLine = nPerLine - 1
      }

      func __appendSemicolonSP() {
        if remainingUTF8CountInCurrentLine < 1 {
          __appendCRLFSP()
        }
        __append(._semicolon)
        if remainingUTF8CountInCurrentLine <= 1 {
          __appendCRLFSP()
        } else {
          __append(._space)
        }
      }

      func __append(_ string: String) -> Bool {
        if string.isContiguousUTF8 {
          let utf8 = string.utf8
          let utf8Count = utf8.count

          func __appendUTF8() {
            descData.append(contentsOf: utf8)
            remainingUTF8CountInCurrentLine -= utf8Count
            assert(remainingUTF8CountInCurrentLine >= 0)
          }

          if utf8Count < remainingUTF8CountInCurrentLine {
            __appendUTF8()
            return true
          } else if utf8Count == remainingUTF8CountInCurrentLine {
            __appendUTF8()
            __appendCRLFSP()
            return true
          } else {
            guard utf8Count < nPerLine else {
              return false
            }
            __appendCRLFSP()
            __appendUTF8()
            return true
          }
        } else {
          switch string._compareUTF8Count(with: remainingUTF8CountInCurrentLine) {
          case .orderedAscending:
            string.utf8.forEach(__append)
            return true
          case .orderedSame:
            string.utf8.forEach(__append)
            __appendCRLFSP()
            return true
          case .orderedDescending:
            if string._compareUTF8Count(with: nPerLine - 1) == .orderedDescending {
              return false
            }
            __appendCRLFSP()
            string.utf8.forEach(__append)
            return true
          }
        }
      }

      // "Content-Disposition: "
      remainingUTF8CountInCurrentLine -= HTTPHeaderFieldName.contentDisposition.rawValue.utf8.count + 2

      let typeDesc = self.type.rawValue
      guard __append(typeDesc) else {
        throw .dispositionTypeTooLong
      }

      if let parameterList = self.parameterList {
        guard let fixedList = parameterList.fixed(for: .mime, sortParameters: true) else {
          throw .failedToConvertParameterListForMIME
        }

        for parameter in fixedList {
          __appendSemicolonSP()
          guard __append(parameter.description) else {
            throw .unexpectedParameterDescription(parameter)
          }
        }
      }

      return String(decoding: descData, as: UTF8.self)
    }
  }
}

public struct ContentDispositionParser<Input>: StringParser where Input: StringProtocol {
  public typealias Output = ContentDisposition

  let _string: Input

  public init(input: Input) {
    self._string = input
  }

  public func parse() -> (output: ContentDisposition, endIndex: Input.Index)? {
    guard let (token, tokenEndIndex) = HTTPTokenParser<Input>.parse(_string) else {
      return nil
    }
    let type = ContentDisposition.DispositionType(rawValue: token._string)

    if let (_, sepEndIndex) = _SemicolonSeparatorParser<Input.SubSequence>.parse(_string[tokenEndIndex...]) {
      guard let (list, listEndIndex) = HTTPHeaderFieldParameterListParser<Input.SubSequence>.parse(
        _string[sepEndIndex...]
      ) else {
        return (ContentDisposition(type: type, parameterList: nil), sepEndIndex)
      }
      return (ContentDisposition(type: type, parameterList: list), listEndIndex)
    }
    return (ContentDisposition(type: type, parameterList: nil), tokenEndIndex)
  }
}

extension ContentDisposition: LosslessStringConvertible {
  /// Initialize with `string`
  ///
  /// - NOTE: This initializer is NOT failable for backward compatibility.😓
  public init<S>(_ string: S) where S: StringProtocol {
    var index = string.startIndex
    if let (_, spEndIndex) = LinearWhitespaceParser<S>.parse(string) {
      index = spEndIndex
    }
    guard let (contentDisposition, _) = ContentDispositionParser<S.SubSequence>.parse(
      string[index...]
    ) else {
      self.init(type: .attachment)
      return
    }
    self = contentDisposition
  }
}
