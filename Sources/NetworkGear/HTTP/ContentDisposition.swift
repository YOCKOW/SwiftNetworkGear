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

  public typealias ParameterKey = ContentDispositionParameterKey

  /// A [Disposition Type](https://datatracker.ietf.org/doc/html/rfc6266#section-4.2).
  public var type: DispositionType

  @available(*, deprecated, renamed: "type")
  public var value: Value { type }

  public var parameters: [ParameterKey:String]?

  public init(type: DispositionType, parameters: [ParameterKey: String]? = nil) {
    self.type = type
    self.parameters = parameters
  }

  @available(*, deprecated, renamed: "init(type:parameters:)")
  public init(value: Value, parameters: [ParameterKey: String]? = nil) {
    self.init(type: value, parameters: parameters)
  }
}

extension ContentDisposition: Equatable, Hashable {
  public static func ==(lhs:ContentDisposition, rhs:ContentDisposition) -> Bool {
    return lhs.type == rhs.type && lhs.parameters == rhs.parameters
  }
  
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self.type)
    hasher.combine(self.parameters)
  }
}

extension ContentDisposition: CustomStringConvertible {
  /// Description for the content disposition.
  /// e.g.) attachment; filename="filename.jpg"
  public var description: String {
    var desc = self.type.rawValue
    if let parameters = self.parameters {
      for (key, value) in parameters {
        let escapedValue = value.replacingOccurrences(of:"\\", with:"\\\\").replacingOccurrences(of:"\"", with:"\\\"")
        desc += "; \(key.rawValue)=\"\(escapedValue)\""
      }
    }
    return desc
  }
}

extension ContentDisposition {
  /// Initialize with `string`
  public init(_ string:String) {
    let (type_s, parameters_s) = string.splitOnce(separator:";")
    let type = DispositionType(rawValue: String(type_s).trimmingCharacters(in:.whitespaces))
    if parameters_s == Optional<Substring>.none {
      self.init(type: type, parameters: nil)
    } else {
      let parameters = Dictionary<ParameterKey,String>(parsing:String(parameters_s!)) {
        let key = ParameterKey(rawValue:$0)
        let value = $1
        return (key, value)
      }
      
      self.init(type: type, parameters: parameters)
    }
  }
}
