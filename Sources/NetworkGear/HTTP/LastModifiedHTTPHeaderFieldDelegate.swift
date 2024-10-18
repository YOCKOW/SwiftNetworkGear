/* *************************************************************************************************
 LastModifiedHTTPHeaderFieldDelegate.swift
   © 2017-2018,2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

public struct LastModifiedHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate, Sendable {
  public typealias HTTPHeaderFieldValueSource = Date
  
  public static var name: HTTPHeaderFieldName { return .lastModified }
  public static var type: HTTPHeaderField.PresenceType { return .single }
  
  public var source: Date
  
  public init(_ source: Date) {
    self.source = source
  }
}
