/* *************************************************************************************************
 HTTPHeader.swift
   © 2017-2018,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Represents HTTP Header.
/// Some header fields are contained.
public struct HTTPHeader {
  private var _fieldTable: [HTTPHeaderFieldName:[HTTPHeaderField]]
  private init(_ fieldTable:[HTTPHeaderFieldName:[HTTPHeaderField]]) {
    self._fieldTable = fieldTable
  }
  
  @discardableResult
  public mutating func removeFields(forName name:HTTPHeaderFieldName) -> [HTTPHeaderField] {
    return self._fieldTable.removeValue(forKey:name) ?? []
  }
  
  /// Inserts new field.
  ///
  /// - parameter newField: A field to be inserted into the header.
  /// - parameter removingExistingFields: The existing fields that have the same name with `newField`
  ///                                     will be removed before insertion if this value is `true`.
  ///                                     Fatal error may occur when this value is `false` if any
  ///                                     header fields whose name is the same with `newField` are
  ///                                     already contained in the header and it is not "appendable"
  ///                                     nor "duplicable".
  public mutating func insert(_ newField:HTTPHeaderField, removingExistingFields:Bool = false) {
    let name = newField.name
    
    if removingExistingFields || self._fieldTable[name] == nil {
      self._fieldTable[name] = [newField]
    } else {
      if newField.isDuplicable {
        self._fieldTable[name]!.append(newField)
      } else if newField.isAppendable {
        self._fieldTable[name]![0]._delegate.append(elementsIn:newField._delegate)
      } else {
        fatalError("Header Field named \(name.rawValue) must be single.")
      }
    }
  }
  
  /// Initialize with fields.
  public init<S>(_ fields:S) where S: Sequence, S.Element == HTTPHeaderField {
    self.init([:])
    for field in fields {
      self.insert(field)
    }
  }
  
  public internal(set) subscript(_ name:HTTPHeaderFieldName) -> [HTTPHeaderField] {
    get {
      return self._fieldTable[name] ?? []
    }
    set {
      self._fieldTable.removeValue(forKey:name)
      for field in newValue {
        self.insert(field)
      }
    }
  }
  
  public var count: Int {
    return self._fieldTable.values.reduce(0) { $0 + $1.count }
  }
}

extension HTTPHeader: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = HTTPHeaderField
  public init(arrayLiteral elements: HTTPHeaderField...) {
    self.init(elements)
  }
}

extension HTTPHeader: ExpressibleByDictionaryLiteral {
  public typealias Key = HTTPHeaderFieldName
  public typealias Value = HTTPHeaderFieldValue
  public init(dictionaryLiteral elements: (HTTPHeaderFieldName, HTTPHeaderFieldValue)...) {
    self.init(elements.map({ HTTPHeaderField(name: $0.0, value: $0.1) }))
  }
}

extension HTTPHeader: Sequence {
  public typealias Element = HTTPHeaderField
  public struct Iterator: IteratorProtocol {
    private var _pairIterator: Dictionary<HTTPHeaderFieldName, Array<HTTPHeaderField>>.Iterator
    private var _fieldIterator: Array<HTTPHeaderField>.Iterator!
    fileprivate init(_ header: HTTPHeader) {
      self._pairIterator = header._fieldTable.makeIterator()
      self._fieldIterator = self._pairIterator.next()?.value.makeIterator()
    }
    
    public typealias Element = HTTPHeader.Element
    public mutating func next() -> HTTPHeader.Element? {
      if self._fieldIterator == nil { return nil }
      if let field = self._fieldIterator.next() {
        return field
      } else if let pair = self._pairIterator.next() {
        self._fieldIterator = pair.value.makeIterator()
        return self.next()
      }
      return nil
    }
  }
  
  public func makeIterator() -> HTTPHeader.Iterator {
    return Iterator(self)
  }
}

extension HTTPHeader: CustomStringConvertible {
  public var description: String {
    var desc = ""
    for (name, fields) in self._fieldTable {
      for field in fields {
        desc += "\(name.rawValue): \(field.value.rawValue)\u{000D}\u{000A}"
      }
    }
    desc += "\u{000D}\u{000A}"
    return desc
  }
}


extension HTTPHeader: Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: HTTPHeaderFieldName.self)
    for field in self {
      try container.encode(field.value, forKey: field.name)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: HTTPHeaderFieldName.self)
    var fields: [HTTPHeaderField] = []
    for name in container.allKeys {
      let value = try container.decode(HTTPHeaderFieldValue.self, forKey: name)
      fields.append(.init(name: name, value: value))
    }
    self.init(fields)
  }
}
