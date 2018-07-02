/***************************************************************************************************
 UnicodeScalarView+BidiRule.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import UnicodeSupplement
 
extension String.UnicodeScalarView {
  /// "checkBidi" - Check the Bidi Rule
  /// reference: https://tools.ietf.org/html/rfc5893#section-2
  internal var satisfiesBidiRule: Bool {
    // Rule 1.
    let firstBidi = self.first!.bidirectionality
    guard firstBidi == .leftToRight || firstBidi == .rightToLeft || firstBidi == .arabicLetter else {
      return false
    }
    enum _LabelDirection { case ltr, rtl }
    let direction: _LabelDirection = (firstBidi == .leftToRight) ? .ltr : .rtl
    
    // For rule 2. or 5.
    let availableBidi: Set<Unicode.Scalar.BidiClass> = (direction == .rtl) ? [
      .rightToLeft, .arabicLetter, .arabicNumber,
      .europeanNumber, .europeanSeparator, .commonSeparator, .europeanTerminator,
      .otherNeutral, .boundaryNeutral, .nonspacingMark
    ] : [
      .leftToRight,
      .europeanNumber, .europeanSeparator, .commonSeparator, .europeanTerminator,
      .otherNeutral, .boundaryNeutral, .nonspacingMark
    ]
    
    // For rule 3. or 6
    let availableBidiAtEnd: Set<Unicode.Scalar.BidiClass> = (direction == .rtl) ? [
      .rightToLeft, .arabicLetter, .europeanNumber, .arabicNumber
    ] : [
      .leftToRight, .europeanNumber
    ]
    var endIsOK = false
    
    // For rule 4.
    var includeAN = false
    var includeEN = false
    
    // scan!
    var ii = self.endIndex
    while true {
      if ii == self.startIndex { break }
      ii = self.index(before:ii)
      
      let bidi = self[ii].bidirectionality
      
      //// Check the rule 2. or 5.
      guard availableBidi.contains(bidi) else { return false }
      
      //// Check the rule 3. or 6.
      if !endIsOK {
        if bidi == .nonspacingMark { continue }
        guard availableBidiAtEnd.contains(bidi) else { return false }
        endIsOK = true
      }
      
      //// Check the rule 4.
      if direction == .rtl {
        if bidi == .arabicNumber {
          if includeEN { return false }
          includeAN = true
        } else if bidi == .europeanNumber {
          if includeAN { return false }
          includeEN = true
        }
      }
    } // end of scan...
    
    if !endIsOK { return false }
    
    return true
  }
}
