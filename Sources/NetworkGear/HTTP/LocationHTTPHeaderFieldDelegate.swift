/* *************************************************************************************************
 LocationHTTPHeaderFieldDelegate.swift
   © 2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

public struct LocationHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate {
  public typealias ValueSource = URL
  
  public static var name: HTTPHeaderFieldName { return .location }
  
  public static var type: HTTPHeaderField.PresenceType { return .single }
  
  public var source: URL
  
  public init(_ source: URL) {
    self.source = source
  }
}
