/* *************************************************************************************************
 HTTPHeaderFieldValueConvertible.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that can be converted to/from an instance of `HeaderFieldValue`.
public protocol HTTPHeaderFieldValueConvertible: Hashable {
  init?(_: HTTPHeaderFieldValue)
  init?(_: HTTPHeaderFieldValue, userInfo: [AnyHashable: Any]?)
  var httpHeaderFieldValue: HTTPHeaderFieldValue { get }
}

extension HTTPHeaderFieldValueConvertible {
  /// Default implementation.
  ///
  /// Note: `userInfo` is always ignored when this default implementation is used.
  public init?(_ httpHeaderFieldValue: HTTPHeaderFieldValue, userInfo: [AnyHashable: Any]?) {
    self.init(httpHeaderFieldValue)
  }
}
