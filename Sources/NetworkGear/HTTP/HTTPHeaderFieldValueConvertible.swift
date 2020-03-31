/* *************************************************************************************************
 HTTPHeaderFieldValueConvertible.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that can be converted to/from an instance of `HeaderFieldValue`.
public protocol HTTPHeaderFieldValueConvertible: Hashable {
  init?(headerFieldValue:HTTPHeaderFieldValue)
  init?(headerFieldValue:HTTPHeaderFieldValue, userInfo: [AnyHashable: Any]?)
  var headerFieldValue:HTTPHeaderFieldValue { get }
}

extension HTTPHeaderFieldValueConvertible {
  /// Default implementation.
  ///
  /// Note: `userInfo` is always ignored when this default implementation is used.
  public init?(headerFieldValue:HTTPHeaderFieldValue, userInfo: [AnyHashable: Any]?) {
    self.init(headerFieldValue: headerFieldValue)
  }
}
