/***************************************************************************************************
 Domain.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import Foundation
import Bootstring

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
    
    
    fileprivate var _string:String
    fileprivate var _length:Int
    
    /// Initialize with `string`.
    public init(_ string:String,
                options:ValidityOptions = .default) throws {
      var string = string
      
      // not zero-length
      if string.isEmpty { throw InitializationError.emptyString }
      
      // Decode string with punycode if necessary
      if string.hasPrefix("xn--") {
        let rr = string.range(of:"xn--", options:.anchored)!.upperBound..<string.endIndex
        guard let decoded = String(string[rr]).removingPunycodeEncoding else {
          throw InitializationError.invalidIDNLabel
        }
        string = decoded
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
        guard scalars.satisfiesBidiRule else { throw InitializationError.violatingBidiRule }
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
        if scalar.isContextJoiner && options.contains(.checkJoiners) {
          guard scalars.satisfiesContextJRules(at:ii) else {
            throw InitializationError.vaiolatingContextJRules
          }
        }
        
        // Check ContextO Rules
        if scalar.isContextOther && options.contains(.checkOtherContextualRules) {
          guard scalars.satisfiesContextORules(at:ii) else {
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
    }
  } // end of `Label`

//// Define `Domain`
  
  /// `Domain` consists of labels
  internal var _labels: [Label]
  private var _terminatedByDot: Bool = false
  private var _length: Int
  internal var _options: Label.ValidityOptions

  /// Initialize with string such as "YOCKOW.jp"
  public init?(_ string:String,
               options: Label.ValidityOptions = .default) {
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
    
    var string_labels = String(converted).precomposedStringWithCanonicalMapping.components(separatedBy:".")
    guard let last = string_labels.last else { return nil }
    
    if last.isEmpty {
      self._terminatedByDot = true
      string_labels.removeLast()
    }
    
    var labels:[Label] = []
    for string_label in string_labels {
      guard let label = try? Label(string_label, options:options) else { return nil }
      labels.append(label)
    }
    
    if labels.isEmpty { return nil }
    
    var length: Int = labels.count - 1
    for label in labels {
      length += label._length
    }
    
    if options.contains(.verifyDNSLength) {
      let max = self._terminatedByDot ? 254 : 253
      if length < 1 || length > max { return nil }
    }
    
    self._labels = labels
    self._length = length
    
    self._options = options
  }
}


extension Domain.Label: CustomStringConvertible {
  public var description: String {
    return self._string
  }
}

extension Domain: CustomStringConvertible {
  public var description: String {
    var desc = self._labels.map{$0.description}.joined(separator:".")
    if self._terminatedByDot { desc += "." }
    return desc
  }
}

extension Domain.Label: Hashable {
  public static func ==(lhs:Domain.Label, rhs:Domain.Label) -> Bool {
    return lhs._string == rhs._string
  }
  
  public var hashValue:Int {
    return self._string.hashValue
  }
}

extension Domain: Hashable {
  public static func ==(lhs:Domain, rhs:Domain) -> Bool {
    let lLabels = lhs._labels, rLabels = rhs._labels
    guard lLabels.count == rLabels.count else { return false }
    for ii in 0..<lLabels.count {
      if lLabels[ii] != rLabels[ii] { return false }
    }
    return true
  }
  
  public var hashValue: Int {
    var hh = 0
    for label in  self._labels {
      hh ^= label.hashValue
    }
    return hh
  }
}
