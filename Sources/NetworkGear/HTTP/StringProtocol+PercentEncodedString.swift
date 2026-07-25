/* *************************************************************************************************
 StringProtocol+PercentEncodedString.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import yExtensions

private extension UInt8 {
  func _addPercentEncodedBytes<C>(to collection: inout C)
  where C: RangeReplaceableCollection, C.Element == UInt8 {
    func __hex(of uint8: UInt8) -> UInt8 {
      assert(uint8 <= 0x0F)
      switch uint8 {
      case 0...9: return uint8 + 0x30 // "0"..."9"
      default: return uint8 - 10 + 0x41 // "A"..."F"
      }
    }
    collection.append(._percentSign)
    collection.append(__hex(of: self >> 4))
    collection.append(__hex(of: self & 0x0F))
  }

  var _hexValue: UInt8? {
    switch self {
    case 0x30...0x39: return self - 0x30
    case 0x41...0x5A: return self - 0x41 + 10
    case 0x61...0x7A: return self - 0x61 + 10
    default: return nil
    }
  }
}

private extension Sequence where Self.Element == UInt8 {
  func _addingPercentEncoding(withAllowedBytes isAllowedByte: (UInt8) throws -> Bool) rethrows -> Data {
    var output = Data()
    for byte in self {
      if try !byte._isPercentSign && isAllowedByte(byte) {
        output.append(byte)
      } else {
        byte._addPercentEncodedBytes(to: &output)
      }
    }
    return output
  }

  var _removingPercentEncoding: Data? {
    var result = Data()
    var myIterator = self.makeIterator()
    while let byte = myIterator.next() {
      if byte._isPercentSign {
        guard let h1 = myIterator.next(),
              let b1 = h1._hexValue,
              let h2 = myIterator.next(),
              let b2 = h2._hexValue else {
          return nil
        }
        result.append((b1 << 4) | b2)
      } else { // byte != _PERCENT
        result.append(byte)
      }
    }
    return result
  }
}

extension StringProtocol {
  public func addingPercentEncoding(
    usingStringEncoding stringEncoding: String.Encoding,
    whereAllowedUnicodeScalars isAllowedUnicodeScalar: (Unicode.Scalar) throws -> Bool
  ) rethrows -> String? {
    var outputData = Data()

    if stringEncoding == .utf8 {
      for scalar in self.unicodeScalars {
        if try isAllowedUnicodeScalar(scalar) {
          outputData.append(contentsOf: scalar.utf8)
        } else {
          scalar.utf8.forEach({ $0._addPercentEncodedBytes(to: &outputData) })
        }
      }
    } else { // stringEncoding != .utf8
      for scalar in self.unicodeScalars {
        guard let scalarData = String(scalar).data(using: stringEncoding) else {
          return nil
        }
        if try isAllowedUnicodeScalar(scalar) {
          outputData.append(contentsOf: scalarData)
        } else {
          var percentEncodedScalarData = Data()
          scalarData.forEach({ $0._addPercentEncodedBytes(to: &percentEncodedScalarData) })
          guard let percentEncoded = String(
            decoding: percentEncodedScalarData,
            as: Unicode.UTF8.self
          ).data(using: stringEncoding) else {
            return nil
          }
          outputData.append(contentsOf: percentEncoded)
        }
      }
    }
    return String(data: outputData, encoding: stringEncoding)
  }

  @inlinable
  public func addingPercentEncoding(whereAllowedUnicodeScalars isAllowedUnicodeScalar: (Unicode.Scalar) throws -> Bool) rethrows -> String? {
    return try self.addingPercentEncoding(
      usingStringEncoding: .utf8,
      whereAllowedUnicodeScalars: isAllowedUnicodeScalar
    )
  }

  public func addingPercentEncoding(
    usingStringEncoding stringEncoding: String.Encoding,
    whereAllowedASCIICharacters isAllowedASCIICharacter: (Unicode.UTF8.CodeUnit) throws -> Bool
  ) rethrows -> String? {
    guard let stringData: any Sequence<UInt8> = (stringEncoding == .utf8) ? self.utf8 : self.data(using: stringEncoding) else {
      return nil
    }
    let encodedData = try stringData._addingPercentEncoding(withAllowedBytes: {
      try $0 < 0x80 && isAllowedASCIICharacter($0)
    })
    return String(data: encodedData, encoding: .ascii)
  }

  @inlinable
  public func addingPercentEncoding(
    whereAllowedASCIICharacters isAllowedASCIICharacter: (Unicode.UTF8.CodeUnit) throws -> Bool
  ) rethrows -> String? {
    return try self.addingPercentEncoding(
      usingStringEncoding: .utf8,
      whereAllowedASCIICharacters: isAllowedASCIICharacter
    )
  }
}

private extension StringProtocol {
  func _utf8CodeUnit(at index: String.Index) -> UTF8.CodeUnit {
    return self.utf8[index]
  }

  func _utf8Index(after index: String.Index) -> String.Index {
    return self.utf8.index(after: index)
  }

  func _formUTF8Index(after index: inout String.Index) {
    self.utf8.formIndex(after: &index)
  }

  func _utf8Index(_ index: String.Index, offsetBy distance: Int) -> String.Index {
    return self.utf8.index(index, offsetBy: distance)
  }
}

/// A workaround for the feature(?) that `UTF8View` is not `BidirectionalCollection`.
///
/// See Also: [Can we require StringProtocol.UTF8View be a BidirectionalCollection?](https://forums.swift.org/t/can-we-require-stringprotocol-utf8view-be-a-bidirectionalcollection/44951)
private protocol _BidirectionalUTF8View: BidirectionalCollection,
                                         Sendable where Element == UTF8.CodeUnit,
                                                        Index == String.Index {}
extension String.UTF8View: _BidirectionalUTF8View {}
extension Substring.UTF8View: _BidirectionalUTF8View {}

private protocol _BidirectionalUTF8ViewAvailableStringProtocol: Sendable {
  associatedtype BidirectionalUTF8View: _BidirectionalUTF8View
  var utf8: BidirectionalUTF8View { get }
}
extension String: _BidirectionalUTF8ViewAvailableStringProtocol {}
extension Substring: _BidirectionalUTF8ViewAvailableStringProtocol {}

extension _BidirectionalUTF8ViewAvailableStringProtocol {
  func _utf8Index(before index: String.Index) -> String.Index {
    return self.utf8.index(before: index)
  }

  func _formUTF8Index(before index: inout String.Index) {
    return self.utf8.formIndex(before: &index)
  }
}


/// A string that is encoded with [Percent-Encoding](https://datatracker.ietf.org/doc/html/rfc3986#section-2.1).
public struct PercentEncodedString: Sendable, Equatable, Hashable {
  /// Valid percent-encoded string.
  ///
  /// The type of this property is either `String` or `Substring`.
  fileprivate let _encodedString: any StringProtocol & _BidirectionalUTF8ViewAvailableStringProtocol

  public var utf8Count: Int {
    return _encodedString.utf8.count
  }

  public static func ==(lhs: PercentEncodedString, rhs: PercentEncodedString) -> Bool {
    var lUTF8Iterator = lhs._encodedString.utf8.makeIterator()
    var rUTF8Iterator = rhs._encodedString.utf8.makeIterator()
    while let lByte = lUTF8Iterator.next() {
      guard let rByte = rUTF8Iterator.next(), lByte == rByte else {
        return false
      }
    }
    return rUTF8Iterator.next().isNil
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self._encodedString)
  }

  private final class _Converted: @unchecked Sendable {
    private let _stringQueue: DispatchQueue = .init(
      label: "jp.YOCKOW.NetworkGear.PercentEncodedString.String",
      attributes: .concurrent
    )
    private let _dataQueue: DispatchQueue = .init(
      label: "jp.YOCKOW.NetworkGear.PercentEncodedString.Data",
      attributes: .concurrent
    )
    private var _string: String? = nil
    private var _decodedData: Data? = nil

    func getString<S>(from anyString: S) -> String where S: StringProtocol {
      return _stringQueue.sync(flags: .barrier) {
        guard let string = self._string else {
          let string = anyString._string
          self._string = string
          return string
        }
        return string
      }
    }

    func decode<S>(_ string: S) -> Data where S: StringProtocol {
      return _dataQueue.sync(flags: .barrier) {
        guard let decodedData = self._decodedData else {
          let decodedData = string.utf8._removingPercentEncoding!
          self._decodedData = decodedData
          return decodedData
        }
        return decodedData
      }
    }
  }
  private let _converted: _Converted = .init()

  public var encodedString: String {
    return _converted.getString(from: _encodedString)
  }

  public var decodedData: Data {
    return _converted.decode(_encodedString)
  }

  /// Decodes percent-encoded string and returns a string using the given string encoding.
  public func decodedString(usingStringEncoding stringEncoding: String.Encoding) -> String? {
    return String(data: self.decodedData, encoding: stringEncoding)
  }

  /// Decodes percent-encoded string.
  @inlinable
  public var decodedString: String? {
    return self.decodedString(usingStringEncoding: .utf8)
  }

  /// - parameters:
  ///   - encodedString: A string that has been already **validated** as a percent-encoded string.
  ///
  /// - Note: This initializer should not be `public`.
  internal init<S>(encodedString: S) where S: StringProtocol {
    if case let substring as Substring = encodedString {
      self._encodedString = substring
    } else if case let string as String = encodedString {
      self._encodedString = string
    } else {
      self._encodedString = encodedString._string
    }
  }
}


/// A parser to parse a percent-encoded string.
public struct PercentEncodedStringParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = PercentEncodedString

  public struct Configuration {
    public let allowedNonEncodedUTF8CodeUnits: (Unicode.UTF8.CodeUnit) -> Bool

    public init(allowedNonEncodedUTF8CodeUnits: @escaping (Unicode.UTF8.CodeUnit) -> Bool = { $0._isVisible } ) {
      self.allowedNonEncodedUTF8CodeUnits = allowedNonEncodedUTF8CodeUnits
    }
  }

  let input: Input
  let utf8: Input.UTF8View
  public let configuration: Configuration

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration ?? .init()
  }

  public init(input: Input, allowedNonEncodedUTF8CodeUnits: @escaping (Unicode.UTF8.CodeUnit) -> Bool) {
    self.init(
      input: input,
      configuration: .init(allowedNonEncodedUTF8CodeUnits: allowedNonEncodedUTF8CodeUnits)
    )
  }

  public mutating func parse() -> (output: PercentEncodedString, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    func __parsePercentEncoded() -> Bool {
      var currentIndexForPercentEncoded = currentIndex
      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndexForPercentEncoded,
        ifAllowedCodeUnit: \._isPercentSign
      ) else {
        return false
      }
      guard let _ = self.parseString(
        from: &currentIndexForPercentEncoded,
        minCount: 2,
        maxCount: 2,
        while: \._isHexDigit
      ) else {
        return false
      }
      currentIndex = currentIndexForPercentEncoded
      return true
    }

    while currentIndex < self.utf8.endIndex {
      if __parsePercentEncoded() {
        continue
      }
      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: {
          !$0._isPercentSign && configuration.allowedNonEncodedUTF8CodeUnits($0)
        }
      ) else {
        break
      }
    }
    return (
      PercentEncodedString(encodedString: input[..<currentIndex]),
      currentIndex
    )
  }
}

extension PercentEncodedString: _InitializableWithParser {
  /// Creates an instance from given `string`.
  public init?<S>(
    validating string: S,
    configuration: PercentEncodedStringParser<S>.Configuration? = nil
  ) where S: StringProtocol {
    self.init(
      string,
      parser: PercentEncodedStringParser<S>.self,
      configuration: configuration
    )
  }

  /// Creates an instance from given `string`.
  public init?<S>(
    validating string: S,
    whereAllowedNonEncodedUTF8CodeUnits allowedNonEncodedUTF8CodeUnits: @escaping (Unicode.UTF8.CodeUnit) -> Bool
  ) where S: StringProtocol {
    self.init(
      validating: string,
      configuration: .init(allowedNonEncodedUTF8CodeUnits: allowedNonEncodedUTF8CodeUnits)
    )
  }
}


extension PercentEncodedString: Sequence, Collection {
  public struct Index: Sendable, Equatable, Comparable {
    /// Start index of `_encodedString`.
    fileprivate let _stringIndex: String.Index

    fileprivate init(stringIndex: String.Index) {
      self._stringIndex = stringIndex
    }

    public static func ==(lhs: Index, rhs: Index) -> Bool {
      return lhs._stringIndex == rhs._stringIndex
    }

    public static func <(lhs: Index, rhs: Index) -> Bool {
      return lhs._stringIndex < rhs._stringIndex
    }
  }

  public enum Element: Sendable, Equatable {
    case percentEncoded(upperHex: Unicode.UTF8.CodeUnit, lowerHex: Unicode.UTF8.CodeUnit)
    case rawCodeUnit(Unicode.UTF8.CodeUnit)

    public static func ==(lhs: Element, rhs: Element) -> Bool {
      switch (lhs, rhs) {
      case (.percentEncoded(let lUpper, let lLower), .percentEncoded(let rUpper, lowerHex: let rLower)):
        return lUpper._hexValue == rUpper._hexValue && lLower._hexValue == rLower._hexValue
      case (.rawCodeUnit(let lByte), .rawCodeUnit(let rByte)):
        return lByte == rByte
      default:
        return false
      }
    }

    public var decodedCodeUnit: Unicode.UTF8.CodeUnit {
      switch self {
      case .percentEncoded(let upperHex, let lowerHex):
        return (upperHex._hexValue! << 4) | lowerHex._hexValue!
      case .rawCodeUnit(let codeUnit):
        return codeUnit
      }
    }
  }

  public var startIndex: Index {
    return Index(stringIndex: self._encodedString.startIndex)
  }

  public var endIndex: Index {
    return Index(stringIndex: self._encodedString.endIndex)
  }

  public subscript(_ index: Index) -> Element {
    assert(index < self.endIndex)
    let firstByte = self._encodedString._utf8CodeUnit(at: index._stringIndex)
    if firstByte._isPercentSign {
      var hexIndex = self._encodedString._utf8Index(after: index._stringIndex)
      let upperHex = self._encodedString._utf8CodeUnit(at: hexIndex)
      self._encodedString._formUTF8Index(after: &hexIndex)
      let lowerHex = self._encodedString._utf8CodeUnit(at: hexIndex)
      return .percentEncoded(upperHex: upperHex, lowerHex: lowerHex)
    } else {
      return .rawCodeUnit(firstByte)
    }
  }

  private func _index(after i: Index) -> (nextIndex: Index, currentElementIsPercentEncoded: Bool) {
    let stringIndex = i._stringIndex
    let byte = self._encodedString._utf8CodeUnit(at: stringIndex)
    if byte._isPercentSign {
      return (Index(stringIndex: self._encodedString._utf8Index(stringIndex, offsetBy: 3)), true)
    } else {
      return (Index(stringIndex: self._encodedString._utf8Index(after: stringIndex)), false)
    }
  }

  public func index(after i: Index) -> Index {
    return self._index(after: i).nextIndex
  }

  @inlinable
  public func formIndex(after i: inout Index) {
    i = self.index(after: i)
  }

  public var isEmpty: Bool {
    return self._encodedString.isEmpty
  }

  /// The end index to which `utf8Count` of the subsequence from start is less than or equal to `maxUTF8Count`.
  public func endIndex(whereMaxUTF8Count maxUTF8Count: Int) -> Index {
    let endIndex = self.endIndex
    var currentIndex = self.startIndex
    var currentUTF8Count = 0
    while currentIndex < endIndex {
      let (nextIndex, currentElementIsPercentEncoded) = _index(after: currentIndex)
      currentUTF8Count += currentElementIsPercentEncoded ? 3 : 1
      if currentUTF8Count > maxUTF8Count {
        return currentIndex
      }
      currentIndex = nextIndex
    }
    return currentIndex
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = PercentEncodedString.Element

    private var _currentIndex: PercentEncodedString.Index
    private let _percentEncodedString: PercentEncodedString

    fileprivate init(_ percentEncodedString: PercentEncodedString) {
      self._currentIndex = percentEncodedString.startIndex
      self._percentEncodedString = percentEncodedString
    }

    public mutating func next() -> Element? {
      guard _currentIndex < _percentEncodedString.endIndex else {
        return nil
      }
      let element = _percentEncodedString[_currentIndex]
      _percentEncodedString.formIndex(after: &_currentIndex)
      return element
    }
  }

  public func makeIterator() -> Iterator {
    return Iterator(self)
  }

  public typealias SubSequence = PercentEncodedString

  public subscript(_ bounds: Range<Index>) -> SubSequence {
    let substring = self._encodedString[bounds.lowerBound._stringIndex..<bounds.upperBound._stringIndex]
    return PercentEncodedString(encodedString: substring)
  }
}

extension PercentEncodedString: BidirectionalCollection {
  public func index(before i: Index) -> Index {
    // Determine if the previous `Element` is percent encoded or not.

    let prevStringIndex = self._encodedString._utf8Index(before: i._stringIndex)
    if prevStringIndex == self._encodedString.startIndex {
      return Index(stringIndex: prevStringIndex)
    }

    let prevByte = self._encodedString._utf8CodeUnit(at: prevStringIndex)
    if !prevByte._isHexDigit {
      return Index(stringIndex: prevStringIndex)
    }

    let prevPrevStringIndex = self._encodedString._utf8Index(before: prevStringIndex)
    if prevPrevStringIndex == self._encodedString.startIndex {
      return Index(stringIndex: prevStringIndex)
    }

    let prevPrevByte = self._encodedString._utf8CodeUnit(at: prevPrevStringIndex)
    if !prevPrevByte._isHexDigit {
      return Index(stringIndex: prevStringIndex)
    }

    let prevPrevPrevStringIndex = self._encodedString._utf8Index(before: prevPrevStringIndex)
    guard self._encodedString._utf8CodeUnit(at: prevPrevPrevStringIndex)._isPercentSign else {
      return Index(stringIndex: prevStringIndex)
    }
    return Index(stringIndex: prevPrevPrevStringIndex)
  }
}
