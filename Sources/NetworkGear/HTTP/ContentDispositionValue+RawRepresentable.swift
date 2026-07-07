/* *************************************************************************************************
 ContentDispositionValue+RawRepresentable.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

extension ContentDispositionValue: RawRepresentable {
  public typealias RawValue = String

  @inlinable
  public var rawValue: String {
    if case .dispositionType(let string) = self {
      return String(describing: string)
    }
    return ContentDispositionValue._registeredCaseToString[self]!
  }

  @inlinable
  public init(rawValue: String) {
    if let value = ContentDispositionValue._stringToRegisteredCase(rawValue) {
      self = value
    } else if let string = ASCIICaseInsensitiveHTTPTokenString(rawValue) {
      self = .dispositionType(string)
    } else {
      self = .attachment
    }
  }
}
