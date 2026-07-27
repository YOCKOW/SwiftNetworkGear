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
