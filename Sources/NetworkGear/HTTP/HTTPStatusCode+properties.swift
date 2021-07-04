/* *************************************************************************************************
 HTTPStatusCode+properties.swift
   © 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

extension HTTPStatusCode {
  /// Returns the Boolean value that indicates whether or not the status means success.
  @inlinable
  public var isOK: Bool {
    return self.rawValue / 100 == 2
  }

  /// Returns the Boolean value that indicates whether or not the status requires `Location` HTTP Header.
  @inlinable
  public var requiresLocationHeader: Bool {
    return self.rawValue / 100 == 3 || self.rawValue == 201
  }
}
