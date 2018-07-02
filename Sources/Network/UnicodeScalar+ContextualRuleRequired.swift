/***************************************************************************************************
 UnicodeScalar+ContextualRuleRequired.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import UnicodeSupplement

extension Unicode.Scalar {
  /// Returns whether the receiver is a joiner (of ContextJ) or not.
  internal var isContextJoiner: Bool {
    return self.isJoinControl
  }
  
  
  /// Returns whether the receiver is a scalar that requires contextual rule, and is not a joiner.
  internal var isContextOther: Bool {
    // https://tools.ietf.org/html/rfc5892#page-8
    switch self.value {
    case 0x00B7: // MIDDLE DOT
      return true
    case 0x0375: // GREEK LOWER NUMERAL SIGN (KERAIA)
      return true
    case 0x05F3: // HEBREW PUNCTUATION GERESH
      return true
    case 0x05F4: // HEBREW PUNCTUATION GERSHAYIM
      return true
    case 0x30FB: //  KATAKANA MIDDLE DOT
      return true
    case 0x0660...0x0669: // ARABIC-INDIC DIGITs
      return true
    case 0x06F0...0x06F9: // EXTENDED ARABIC-INDIC DIGITs
      return true
    default:
      return false
    }
  }
}
