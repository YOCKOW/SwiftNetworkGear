/* *************************************************************************************************
 HTTPHeaderFieldDelegate.swift
   © 2018-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public protocol HTTPHeaderFieldDelegate: Hashable {
  associatedtype ValueSource: HTTPHeaderFieldValueConvertible
  
  /// The name of the header field.
  static var name: HTTPHeaderFieldName { get }
  
  /// The representation how it can exist in the header.
  static var type: HTTPHeaderField.PresenceType { get }
  
  /// The source that generates the value of the header field.
  var source: ValueSource { get }
  
  /// Initializes with an instance of `ValueSource`.
  init(_ source: ValueSource)
}

extension HTTPHeaderFieldDelegate {
  /// The value of the header field.
  public var value: HTTPHeaderFieldValue {
    return self.source.headerFieldValue
  }
}

extension HTTPHeaderFieldDelegate where ValueSource: Equatable {
  public static func ==(lhs:Self, rhs:Self) -> Bool {
    return lhs.source == rhs.source
  }
}

extension HTTPHeaderFieldDelegate where ValueSource: Hashable {
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self.source)
  }
}

/// Header field whose type is `appendable`.
public protocol AppendableHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate {
  associatedtype Element
  
  /// The source that generates the value of the header field.
  var source: ValueSource { get set }
  
  /// The elements contained in the header field.
  var elements: [Element] { get }
  
  /// Append the element
  mutating func append(_ element:Element)
  
  /// Append the elements
  mutating func append<S>(contentsOf elements:S) where S: Sequence, S.Element == Element
}

extension AppendableHTTPHeaderFieldDelegate
  where ValueSource:RangeReplaceableCollection, ValueSource.Element == Element
{
  public mutating func append(_ element:Element) {
    self.source.append(element)
  }
  
  public mutating func append<S>(contentsOf elements:S) where S: Sequence, S.Element == Element {
    self.source.append(contentsOf:elements)
  }
}
