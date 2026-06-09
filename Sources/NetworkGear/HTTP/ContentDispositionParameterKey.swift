/* *************************************************************************************************
 ContentDispositionParameterKey.swift
   © 2018-2019,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Represents the key for parameter of Content Disposition.
/// It is almost always "filename"
@available(*, deprecated, message: "It is recommended to use 'HTTPHeaderFieldParameter.Name' instead.")
public struct ContentDispositionParameterKey: RawRepresentable,
                                              Sendable,
                                              Hashable,
                                              ExpressibleByStringLiteral {
  public typealias RawValue = String
  public let rawValue: String
  public init(rawValue:String) {
    self.rawValue = rawValue
  }

  public static func ==(lhs:ContentDispositionParameterKey, rhs:ContentDispositionParameterKey) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
  
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self.rawValue)
  }

  public init(stringLiteral string:String) {
    self.init(rawValue:string)
  }
}

@available(*, deprecated)
extension ContentDispositionParameterKey {
  public static let filename = ContentDispositionParameterKey(rawValue: "filename")
  public static let creationDate = ContentDispositionParameterKey(rawValue: "creation-date")
  public static let modificationDate = ContentDispositionParameterKey(rawValue: "modification-date")
  public static let readDate = ContentDispositionParameterKey(rawValue: "read-date")
  public static let size = ContentDispositionParameterKey(rawValue: "size")
  public static let name = ContentDispositionParameterKey(rawValue: "name")
  public static let voice = ContentDispositionParameterKey(rawValue: "voice")
  public static let handling = ContentDispositionParameterKey(rawValue: "handling")
  public static let previewType = ContentDispositionParameterKey(rawValue: "preview-type")
  public static let reaction = ContentDispositionParameterKey(rawValue: "reaction")
}
