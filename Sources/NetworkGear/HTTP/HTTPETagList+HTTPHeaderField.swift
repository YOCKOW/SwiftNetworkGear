/* *************************************************************************************************
 ETagList+HeaderField.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 

extension HTTPETagList: HTTPHeaderFieldValueConvertible {
  public init?(_ value: HTTPHeaderFieldValue) {
    try? self.init(value.rawValue)
  }
  
  public var httpHeaderFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self.description)!
  }
}

extension AppendableHTTPHeaderFieldDelegate where HTTPHeaderFieldValueSource == HTTPETagList, Element == HTTPETag {
  public var elements: Array<HTTPETag> {
    switch self.source {
    case .any: return [.any]
    case .list(let array): return array
    }
  }
  
  public mutating func append(_ element: HTTPETag) {
    self.source.append(element)
  }
  
  public mutating func append<S>(contentsOf elements: S) where S:Sequence, Element == S.Element {
    for etag in elements {
      self.append(etag)
    }
  }
}

/// Generates a header field whose name is "If-Match"
public struct IfMatchHTTPHeaderFieldDelegate: AppendableHTTPHeaderFieldDelegate {
  public typealias HTTPHeaderFieldValueSource = HTTPETagList
  public typealias Element = HTTPETag
  
  public static var name: HTTPHeaderFieldName { return .ifMatch }
  
  public static var type: HTTPHeaderField.PresenceType { return .appendable }
  
  public var source: HTTPETagList
  
  public init(_ source:HTTPETagList) {
    self.source = source
  }
}

/// Generates a header field whose name is "If-None-Match"
public struct IfNoneMatchHTTPHeaderFieldDelegate: AppendableHTTPHeaderFieldDelegate {
  public typealias HTTPHeaderFieldValueSource = HTTPETagList
  public typealias Element = HTTPETag
  
  public static var name: HTTPHeaderFieldName { return .ifNoneMatch }
  
  public static var type: HTTPHeaderField.PresenceType { return .appendable }
  
  public var source: HTTPETagList
  
  public init(_ source: HTTPETagList) {
    self.source = source
  }
}
