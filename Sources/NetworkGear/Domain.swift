/* *************************************************************************************************
 Domain.swift
   © 2018-2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import Foundation
import Bootstring

/// Represents domain name.
public struct Domain {
  /// Represents Domain Label
  public struct Label {
    /// Represents "Unicode IDNA Validity Options"
    public struct ValidityOptions: OptionSet {
      public let rawValue: Int
      public init(rawValue:Int) { self.rawValue = rawValue }
      
      /// Transitional Processing
      public static let transitionalProcessing = ValidityOptions(rawValue:1 << 0)
      /// Use "STD3 ASCII Rules"
      public static let useSTD3ASCIIRules = ValidityOptions(rawValue:1 << 1)
      
      /// Check hyphens
      public static let checkHyphens = ValidityOptions(rawValue:1 << 10)
      /// Check "The Bidi Rule"
      public static let checkBidirectionality = ValidityOptions(rawValue:1 << 11)
      /// Check "ContextJ Rules"
      public static let checkJoiners = ValidityOptions(rawValue:1 << 12)
      /// Check "ContextO Rules"
      public static let checkOtherContextualRules = ValidityOptions(rawValue:1 << 13)
      
      /// Punycode
      public static let addPunycodeEncoding = ValidityOptions(rawValue: 1 << 20)
      /// Verify DNS Length
      public static let verifyDNSLength = ValidityOptions(rawValue: 1 << 21)
      
      /// Indicates IDNA 2008 is used.
      fileprivate static let _idna2008 = ValidityOptions(rawValue:1 << 30)
      
      /// Loose options
      public static let loose: Domain.Label.ValidityOptions = [
        .useSTD3ASCIIRules,
        .addPunycodeEncoding
      ]
      
      /// Default
      public static let `default`:ValidityOptions = [
        .useSTD3ASCIIRules,
        .checkHyphens,
        .checkBidirectionality,
        .checkJoiners,
        .checkOtherContextualRules,
        .addPunycodeEncoding,
        .verifyDNSLength,
      ]
      
      /// IDNA 2008?
      public static let idna2008: ValidityOptions = [
        .transitionalProcessing,
        .useSTD3ASCIIRules,
        .checkHyphens,
        .checkBidirectionality,
        .checkJoiners,
        .checkOtherContextualRules,
        ._idna2008,
      ]
    }
    
    /// Might be thrown by `Domain.Label.init(_:options:)`
    public enum InitializationError: Error {
      case emptyString
      case invalidNormalization
      case firstScalarIsMark
      case invalidIDNLabel
      case inappropriateHyphen
      case violatingBidiRule
      case containingFullStop
      case invalidIDNAStatus
      case vaiolatingContextJRules
      case vaiolatingContextORules
      case invalidLength
    }
    
    /// Raw Label Value.
    internal private(set) var _string: Substring
    
    /// The number of unicode scalars.
    fileprivate private(set) var _length: Int
    
    /// Options that was used in init
    fileprivate private(set) var _options: ValidityOptions
    
    fileprivate init(_ label: Label, options: ValidityOptions) throws {
      if label._options == options {
        self = label
      } else {
        try self.init(label._string, options: options)
      }
    }
    
    /// Initialize with `string`.
    public init<S>(_ string: S,
                   options: ValidityOptions = .default) throws where S: StringProtocol, S.SubSequence == Substring {
      func _forceSubstring<S>(_ s: S) -> Substring where S: StringProtocol, S.SubSequence == Substring {
        return s[s.startIndex..<s.endIndex]
      }
      
      var string = _forceSubstring(string)
      
      // not zero-length
      if string.isEmpty { throw InitializationError.emptyString }
      
      // Decode string with punycode if necessary
      if string.hasPrefix("xn--") {
        guard let decoded = string.dropFirst(4).removingPunycodeEncoding else {
          throw InitializationError.invalidIDNLabel
        }
        string = _forceSubstring(decoded)
      }
      
      // preparation
      let scalars = string.unicodeScalars
      let numberOfScalars = scalars.count
      
      // Check whether the string is NFC or not.
      let nfc: Bool = ({ (ss, nn, cs) -> Bool in
        let cn = cs.count
        guard nn == cn else { return false }
        var ii = ss.startIndex, jj = cs.startIndex
        while true {
          if ii == ss.endIndex || jj == cs.endIndex { break }
          defer {
            ii = ss.index(after:ii)
            jj = cs.index(after:jj)
          }
          guard ss[ii] == cs[jj] else { return false }
        }
        return true
      })(scalars, numberOfScalars, string.precomposedStringWithCanonicalMapping.unicodeScalars)
      guard nfc else { throw InitializationError.invalidNormalization }
      
      
      // First scalar must not be Mark (M*).
      let fgc = scalars.first!.latestProperties.generalCategory
      if fgc == .spacingMark || fgc == .enclosingMark || fgc == .nonspacingMark {
        throw InitializationError.firstScalarIsMark
      }
      
      
      // Check hyphens
      if options.contains(.checkHyphens) {
        if scalars.first! == "\u{002D}" || scalars.last! == "\u{002D}" {
          throw InitializationError.inappropriateHyphen
        }
        if numberOfScalars >= 4 {
          let third = scalars.index(scalars.startIndex, offsetBy:2)
          let fourth = scalars.index(after:third)
          if scalars[third] == "\u{002D}" && scalars[fourth] == "\u{002D}" {
            throw InitializationError.inappropriateHyphen
          }
        }
      }
      
      // "checkBidi" - Check the Bidi Rule
      // reference: https://tools.ietf.org/html/rfc5893#section-2
      if options.contains(.checkBidirectionality) {
        guard scalars._satisfiesBidiRule else { throw InitializationError.violatingBidiRule }
      } // end of checkBidi
      
      
      // scan
      var ii = scalars.startIndex
      var containsNonASCII: Bool = false
      while true {
        if ii == scalars.endIndex { break }
        let scalar = scalars[ii]
        defer { ii = scalars.index(after:ii) }
        
        if scalar > "\u{007F}" { containsNonASCII = true }
        
        // "FULL STOP" is not allowed.
        if scalar == "\u{002E}" { throw InitializationError.containingFullStop }
        
        // Check IDNA status
        guard let status =
          scalar.latestProperties.idnaStatus(usingSTD3ASCIIRules:options.contains(.useSTD3ASCIIRules),
                                             idna2008Compatible:options.contains(._idna2008))
        else {
          throw InitializationError.invalidIDNAStatus
        }
        switch status {
        case .valid: break
        case .deviation: if options.contains(.transitionalProcessing) { throw InitializationError.invalidIDNAStatus }
        default: throw InitializationError.invalidIDNAStatus
        }
        
        // "checkJoiners" - Check Joiners
        if scalar._isContextJoiner && options.contains(.checkJoiners) {
          guard scalars._satisfiesContextJRules(at: ii) else {
            throw InitializationError.vaiolatingContextJRules
          }
        }
        
        // Check ContextO Rules
        if scalar._isContextOther && options.contains(.checkOtherContextualRules) {
          guard scalars._satisfiesContextORules(at: ii) else {
            throw InitializationError.vaiolatingContextORules
          }
        }
        
      } // end of scan
      
      
      // Punycode
      if options.contains(.addPunycodeEncoding) && containsNonASCII {
        guard let encoded = string.addingPunycodeEncoding else {
          throw InitializationError.invalidIDNLabel
        }
        string = "xn--" + encoded
      }
      
      // Verify DNS Length
      let length =  string.unicodeScalars.count
      if options.contains(.verifyDNSLength) {
        if length < 1 || length > 63 { throw InitializationError.invalidLength }
      }
      
      // initialize
      self._string = string
      self._length = length
      self._options = options
    }
  } // end of `Label`

  // - MARK: Definition of `Domain`.
  
  internal static func _calculateLength<C>(of labels: C) -> Int where C: Collection, C.Element == Label {
    return labels.reduce(into: labels.count - 1, { $0 += $1._length })
  }
  
  /// `Domain` consists of labels
  /// Let it be of type `ArraySlice` so that `SubSequence` can be also `Domain`.
  internal private(set) var _labels: ArraySlice<Label>
  private var _length: Int
  private var _terminatedByDot: Bool = false
  internal private(set) var _options: Label.ValidityOptions
  
  public var isTerminatedByDot: Bool {
    return self._terminatedByDot
  }
  
  private init(_validatedLabels labels: ArraySlice<Label>,
               calculatedLength length: Int,
               terminatedByDot: Bool,
               usedOptions options: Label.ValidityOptions) {
    do {
      precondition(!labels.isEmpty, "Empty domain is not allowed.")
      assert(length > 0)
      assert(length == Domain._calculateLength(of: labels))
      assert(labels.allSatisfy({ $0._options == options }))
      assert(!options.contains(.verifyDNSLength) || length <= (terminatedByDot ? 254 : 253))
    }
    
    self._labels = labels
    self._length = length
    self._terminatedByDot = terminatedByDot
    self._options = options
  }
  
  internal init<C>(_ labels: C,
                   terminatedByDot: Bool,
                   options: Label.ValidityOptions) throws where C: Collection, C.Element == Label {
    if labels.isEmpty { throw Label.InitializationError.emptyString }
    
    let labels = try labels.map({ try Label($0, options: options) })
    let length = Domain._calculateLength(of: labels)
    
    if options.contains(.verifyDNSLength) {
      let max = terminatedByDot ? 254 : 253
      guard length > 0 && length <= max else { throw Label.InitializationError.invalidLength }
    }
    
    self.init(_validatedLabels: labels[labels.startIndex..<labels.endIndex],
              calculatedLength: length,
              terminatedByDot: terminatedByDot,
              usedOptions: options)
  }
  
  /// Initialize with string such as "YOCKOW.jp"
  /// Returns `nil` if some domain label(s) is/are invalid.
  public init?<S>(_ string: S,
                  options: Label.ValidityOptions = .default) where S: StringProtocol {
    let input = string.unicodeScalars
    var converted = String.UnicodeScalarView()

    // mapping
    for scalar in input {
      guard let status =
       scalar.latestProperties.idnaStatus(usingSTD3ASCIIRules:options.contains(.useSTD3ASCIIRules),
                                          idna2008Compatible:options.contains(._idna2008))
      else {
        return nil
      }
      
      switch status {
      case .valid:
        converted.append(scalar)
      case .ignored: break
      case .mapped(let results):
        converted.append(contentsOf:results)
      case .deviation(let results):
        if options.contains(.transitionalProcessing) {
          converted.append(contentsOf:results)
        } else {
          converted.append(scalar)
        }
      case .disallowed: return nil
      }
    } // end of mapping
    
    var stringLabels = String(converted).precomposedStringWithCanonicalMapping.split(separator: ".", omittingEmptySubsequences: false)
    guard let last = stringLabels.last else { return nil }
    
    let terminatedByDot = last.isEmpty
    if terminatedByDot { stringLabels.removeLast() }
    guard let labels = try? stringLabels.map({ try Label($0, options: options) }) else { return nil }
    self.init(_validatedLabels: labels[labels.startIndex..<labels.endIndex],
              calculatedLength: Domain._calculateLength(of: labels),
              terminatedByDot: terminatedByDot,
              usedOptions: options)
  }
}

// MARK: - CustomStringConvertible

extension Domain.Label: CustomStringConvertible {
  public var description: String {
    return String(self._string)
  }
}

extension Domain: CustomStringConvertible {
  public var description: String {
    var desc = self._labels.map{$0.description}.joined(separator:".")
    if self._terminatedByDot { desc += "." }
    return desc
  }
}

// MARK: - Equatable and Equatable-like

extension Domain.Label: Equatable {
  public static func ==(lhs: Domain.Label, rhs: Domain.Label) -> Bool {
    return lhs._string == rhs._string
  }
}

extension Domain: Equatable {
  public static func ==(lhs: Domain, rhs: Domain) -> Bool {
    guard lhs.count == rhs.count else { return false }
    var lIter = lhs.makeIterator()
    var rIter = rhs.makeIterator()
    while let lLabel = lIter.next(), let rLabel = rIter.next() {
      if lLabel != rLabel { return false }
    }
    return true
  }
}

extension Domain.Label {
  public static func == <S>(lhs: Domain.Label, rhs: S) -> Bool where S: StringProtocol, S.SubSequence == Substring {
    guard let rLabel = try? Domain.Label(rhs, options: lhs._options) else { return false }
    return lhs == rLabel
  }
}

extension StringProtocol where SubSequence == Substring {
  public static func ==(lhs: Self, rhs: Domain.Label) -> Bool {
    return rhs == lhs
  }
}

extension Optional where Wrapped == Domain.Label {
  public static func ==<S>(lhs: Self, rhs: S?) -> Bool where S: StringProtocol, S.SubSequence == Substring {
    switch (lhs, rhs) {
    case (nil, nil):
      return true
    case (nil, _?), (_?, nil):
      return false
    case (let label?, let string?):
      return label == string
    }
  }
}

extension Optional where Wrapped: StringProtocol, Wrapped.SubSequence == Substring {
  public static func ==(lhs: Self, rhs: Domain.Label?) -> Bool {
    return rhs == lhs
  }
}

// MARK: - Hashable

extension Domain.Label: Hashable {
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self._string)
  }
}

extension Domain: Hashable {
  public func hash(into hasher:inout Hasher) {
    for label in  self._labels {
      hasher.combine(label)
    }
  }
}

// MARK: - Domain Matching

extension Domain {
  /// [Domain Matching](https://tools.ietf.org/html/rfc6265#section-5.1.3).
  /// Used by cookies.
  public func domainMatches(_ another:Domain) -> Bool {
    let numberOfMyLabels = self._labels.count
    let numberOfAnotherLabels = another._labels.count
    guard numberOfMyLabels >= numberOfAnotherLabels else { return false }
    for ii in 0..<numberOfAnotherLabels {
      let myLabel = self._labels[numberOfMyLabels - ii - 1]
      let anotherLabel = another._labels[numberOfAnotherLabels - ii - 1]
      guard myLabel == anotherLabel else { return false }
    }
    return true
  }
}

// MARK: - Sequence, Collection, and BidirectionalCollection

extension Domain: Sequence {
  public typealias Element = Domain.Label
  
  public struct Iterator: IteratorProtocol {
    public typealias Element = Domain.Label
    
    private var _iterator: ArraySlice<Domain.Label>.Iterator
    fileprivate init(_ domain: Domain) {
      self._iterator = domain._labels.makeIterator()
    }
    
    public mutating func next() -> Domain.Label? {
      return self._iterator.next()
    }
  }
  
  public func makeIterator() -> Iterator {
    return Iterator(self)
  }
}

extension Domain: Collection {
  public struct Index: Comparable {
    fileprivate let _index: Int
    fileprivate init(_ index: Int) {
      self._index = index
    }

    public static func ==(lhs: Domain.Index, rhs: Domain.Index) -> Bool {
      return lhs._index == rhs._index
    }

    public static func <(lhs: Domain.Index, rhs: Domain.Index) -> Bool {
      return lhs._index < rhs._index
    }
  }

  public subscript(position: Index) -> Domain.Label {
    return self._labels[position._index]
  }
  
  public var count: Int {
    return self._labels.count
  }
  
  public var startIndex: Index {
    return Index(self._labels.startIndex)
  }
  
  public var endIndex: Index {
    return Index(self._labels.endIndex)
  }
  
  public func index(after ii: Index) -> Index {
    return Index(ii._index + 1)
  }
  
  public typealias SubSequence = Domain
  
  public subscript(bounds: Range<Index>) -> Domain {
    let labels: ArraySlice<Domain.Label> = self._labels[bounds.lowerBound._index..<bounds.upperBound._index]
    return Domain(_validatedLabels: labels,
                  calculatedLength: Domain._calculateLength(of: labels),
                  terminatedByDot: bounds.upperBound == self.endIndex ? self._terminatedByDot : false,
                  usedOptions: self._options)
  }
}

extension Domain: BidirectionalCollection {
  public func index(before ii: Index) -> Index {
    return Index(ii._index - 1)
  }
}
