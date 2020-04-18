/***************************************************************************************************
 UnicodeScalarView+ContextJ.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import UnicodeSupplement

extension BidirectionalCollection where Element == Unicode.Scalar {
  /// Returns whether the receiver satisfies Context J Rules.
  /// Reference: [RFC 5892#Appendix A.](https://tools.ietf.org/html/rfc5892#appendix-A)
  internal func _satisfiesContextJRules(at index: Index) -> Bool {
    if index == self.startIndex { return false }
    let scalar = self[index]
    
    guard scalar._isContextJoiner else { return false }
    
    switch scalar {
    case "\u{200C}"..."\u{200D}":
      if self[self.index(before:index)].latestProperties.canonicalCombiningClass == .virama {
        return true
      }
      if scalar == "\u{200C}" { fallthrough }
    case "\u{200C}":
      // ZERO WIDTH NON-JOINER
      // If RegExpMatch((Joining_Type:{L,D})(Joining_Type:T)*\u200C(Joining_Type:T)*(Joining_Type:{R,D})) Then True;
      
      //// Check the scalars before the joiner.
      var ii = index
      while true {
        if ii == self.startIndex { return false }
        ii = self.index(before:ii)
        
        let scalar = self[ii]
        let joiningType = scalar.latestProperties.joiningType
        if joiningType == .leftJoining || joiningType == .dualJoining { break }
        if joiningType == .transparent { continue }
        return false
      }
      
      //// Check the scalars after the joiner.
      ii = index
      while true {
        ii = self.index(after:ii)
        if ii == self.endIndex { return false }
        
        let scalar = self[ii]
        let joiningType = scalar.latestProperties.joiningType
        if joiningType == .rightJoining || joiningType == .dualJoining { return true }
        if joiningType == .transparent { continue }
        return false
      }
    default:
      fatalError("Unexpected(unimplemented) joiner.")
    }
    
    return false
  }
}
