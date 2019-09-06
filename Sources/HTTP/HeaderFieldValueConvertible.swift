/* *************************************************************************************************
 HeaderFieldValueConvertible.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that can be converted to/from an instance of `HeaderFieldValue`.
public protocol HeaderFieldValueConvertible: Hashable {
  init?(headerFieldValue:HeaderFieldValue)
  init?(headerFieldValue:HeaderFieldValue, userInfo: [AnyHashable: Any]?)
  var headerFieldValue:HeaderFieldValue { get }
}

extension HeaderFieldValueConvertible {
  /// Default implementation.
  ///
  /// Note: `userInfo` is always ignored when this default implementation is used.
  public init?(headerFieldValue:HeaderFieldValue, userInfo: [AnyHashable: Any]?) {
    self.init(headerFieldValue: headerFieldValue)
  }
}
