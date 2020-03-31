/* *************************************************************************************************
 HTTPHeaderFieldDelegate.swift
   © 2018-2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public protocol HTTPHeaderFieldDelegate: Hashable {
  associatedtype HTTPHeaderFieldValueSource
  
  /// The name of the header field.
  static var name: HTTPHeaderFieldName { get }
  
  /// The representation how it can exist in the header.
  static var type: HTTPHeaderField.PresenceType { get }
  
  /// The HTTP field value.
  ///
  /// Default implementation provided where `HTTPHeaderFieldValueSource` conforms to `HTTPHeaderFieldValueConvertible`.
  var value: HTTPHeaderFieldValue { get }
  
  /// The source that generates the value of the header field.
  var source: HTTPHeaderFieldValueSource { get }
  
  /// Initializes with an instance of `HTTPHeaderFieldValueSource`.
  init(_ source: HTTPHeaderFieldValueSource)
  
  /// Initializes with an instance of `HTTPHeaderFieldValue`
  ///
  /// Default implementation provided where `HTTPHeaderFieldValueSource` conforms to `HTTPHeaderFieldValueConvertible`.
  init?(_: HTTPHeaderFieldValue)
}

extension HTTPHeaderFieldDelegate where HTTPHeaderFieldValueSource: HTTPHeaderFieldValueConvertible {
  /// The value of the header field.
  public var value: HTTPHeaderFieldValue {
    return self.source.httpHeaderFieldValue
  }
  
  public init?(_ httpHeaderFieldValue: HTTPHeaderFieldValue) {
    guard let source = HTTPHeaderFieldValueSource(httpHeaderFieldValue) else { return nil }
    self.init(source)
  }
}

extension HTTPHeaderFieldDelegate where HTTPHeaderFieldValueSource: Equatable {
  public static func ==(lhs:Self, rhs:Self) -> Bool {
    return lhs.source == rhs.source
  }
}

extension HTTPHeaderFieldDelegate where HTTPHeaderFieldValueSource: Hashable {
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self.source)
  }
}

/// Header field whose type is `appendable`.
public protocol AppendableHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate {
  associatedtype Element
  
  /// The source that generates the value of the header field.
  var source: HTTPHeaderFieldValueSource { get set }
  
  /// The elements contained in the header field.
  var elements: [Element] { get }
  
  /// Append the element
  mutating func append(_ element:Element)
  
  /// Append the elements
  mutating func append<S>(contentsOf elements:S) where S: Sequence, S.Element == Element
}

extension AppendableHTTPHeaderFieldDelegate
  where HTTPHeaderFieldValueSource: RangeReplaceableCollection, HTTPHeaderFieldValueSource.Element == Element
{
  public mutating func append(_ element:Element) {
    self.source.append(element)
  }
  
  public mutating func append<S>(contentsOf elements:S) where S: Sequence, S.Element == Element {
    self.source.append(contentsOf:elements)
  }
}
