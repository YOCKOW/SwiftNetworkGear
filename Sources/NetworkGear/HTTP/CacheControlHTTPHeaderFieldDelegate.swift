/* *************************************************************************************************
 CacheControlHTTPHeaderFieldDelegate.swift
   © 2017-2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 

/// Represents HTTP Header "Cache-Control"
public struct CacheControlHTTPHeaderFieldDelegate: AppendableHTTPHeaderFieldDelegate {
  public typealias HTTPHeaderFieldValueSource = CacheControlDirectiveSet
  public typealias Element = CacheControlDirective
  
  public static var name: HTTPHeaderFieldName { return .cacheControl }
  public static var type: HTTPHeaderField.PresenceType { return .appendable }
  
  public var source: CacheControlDirectiveSet
  public var elements: [CacheControlDirective] { return self.source._directives }
  
  public init(_ source:CacheControlDirectiveSet) {
    self.source = source
  }
  
  public mutating func append(_ element: CacheControlDirective) {
    self.source.insert(element)
  }
  
  public mutating func append<S>(contentsOf elements: S)
    where S: Sequence, CacheControlDirective == S.Element
  {
    for element in elements {
      self.source.insert(element)
    }
  }
}
