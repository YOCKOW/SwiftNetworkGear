/***************************************************************************************************
 UnicodeScalarView+ContextO.swift
   © 2018-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import UnicodeSupplement

extension BidirectionalCollection where Element == Unicode.Scalar {
  /// Returns whether the receiver satisfies Context O Rules.
  /// Reference: [RFC 5892#Appendix A.](https://tools.ietf.org/html/rfc5892#appendix-A) - A.3-9.
  internal func _satisfiesContextORules(at index: Index) -> Bool {
    let scalar = self[index]
    guard scalar._isContextOther else { return false }
    
    let previousIndex: Index? = (index == self.startIndex) ? nil : self.index(before:index)
    let nextIndex: Index? = ({ (_i: Index) -> Index? in
      let _n = self.index(after:_i)
      return (_n == self.endIndex) ? nil : _n
    })(index)
    
    switch scalar {
    case "\u{00B7}":
      // MIDDLE DOT; https://tools.ietf.org/html/rfc5892#appendix-A.3
      guard let prev = previousIndex, let next = nextIndex else { return false }
      return self[prev] == "\u{006C}" && self[next] == "\u{006C}"
    case "\u{0375}":
      // GREEK LOWER NUMERAL SIGN (KERAIA); https://tools.ietf.org/html/rfc5892#appendix-A.4
      guard let next = nextIndex else { return false }
      return self[next].latestProperties.script == .greek
    case "\u{05F3}", "\u{05F4}":
      // HEBREW PUNCTUATION GERESH; https://tools.ietf.org/html/rfc5892#appendix-A.5
      // HEBREW PUNCTUATION GERSHAYIM; https://tools.ietf.org/html/rfc5892#appendix-A.6
      guard let prev = previousIndex else { return false }
      return self[prev].latestProperties.script == .hebrew
    case "\u{30FB}":
      // KATAKANA MIDDLE DOT; https://tools.ietf.org/html/rfc5892#appendix-A.7
      var ii = self.startIndex
      while true {
        if ii == self.endIndex { break }
        defer { ii = self.index(after:ii) }
        
        let script = self[ii].latestProperties.script
        guard script == .hiragana || script == .katakana || script == .han else { return false }
      }
      return true
    case "\u{0660}"..."\u{0669}":
      // ARABIC-INDIC DIGITS; https://tools.ietf.org/html/rfc5892#appendix-A.8
      var ii = self.startIndex
      while true {
        if ii == self.endIndex { break }
        defer { ii = self.index(after:ii) }
        
        let value = self[ii].value
        if 0x06F0 <= value && value <= 0x06F9 { return false }
      }
      return true
    case "\u{06F0}"..."\u{06F9}":
      // EXTENDED ARABIC-INDIC DIGITS; https://tools.ietf.org/html/rfc5892#appendix-A.9
      var ii = self.startIndex
      while true {
        if ii == self.endIndex { break }
        defer { ii = self.index(after:ii) }
        
        let value = self[ii].value
        if 0x0660 <= value && value <= 0x0669 { return false }
      }
      return true
    default:
      fatalError("Unexpected(unimplemented) scalar.")
    }
  }
}
