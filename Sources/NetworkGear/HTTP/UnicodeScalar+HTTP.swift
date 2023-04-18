/***************************************************************************************************
 UnicodeScalar+HTTP.swift
   © 2017-2018,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

extension Unicode.Scalar {
  private var _isHorizontalTab: Bool { value == 0x09 }
  private var _isSpace: Bool { value == 0x20 }
  private var _isControl: Bool { value <= 0x1F || value == 0x7F }
  /// `tspecials`
  private var _isContentTypeValueSpecial: Bool { "()<>@,;:\\\"/[]?=".unicodeScalars.contains(self) }

  @inlinable internal var _isNewline: Bool {
    switch value {
    case 0x0A...0x0D, 0x85, 0x2028, 0x2029:
      return true
    default:
      return false
    }
  }

  // reference: [RFC 7230](https://tools.ietf.org/html/rfc7230#section-3.2)
  // RFC 7230 says `obs-fold` has been deprecated
  // and `obs-text` should not be used in historical reason. (#3.2.4)
  // `obs-` means obsoleted

  @inlinable internal var _isVisible: Bool { 0x21 <= value && value <= 0x7E }
  @inlinable internal var _isHTTPHeaderFieldDelimiter: Bool { "\"(),/:;<=>?@[\\]{}".unicodeScalars.contains(self) }
  public var isAllowedInHTTPHeaderFieldName: Bool { _isVisible && !_isHTTPHeaderFieldDelimiter }
  public var isAllowedInHTTPHeaderFieldValue: Bool { _isHorizontalTab || _isSpace || _isVisible }


  /// `qdtext` defined in [RFC 7320 §3.2.6](https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.6)
  public var isAllowedInHTTPHeaderFieldValueQuotedText: Bool {
    if _isSpace || _isHorizontalTab {
      return true
    }
    switch value {
    case 0x21, 0x23...0x5B, 0x5D...0x7E:
      return true
    default:
      return false
    }
  }

  public var isHTTPEscapable: Bool { _isHorizontalTab || _isSpace || _isVisible }

  /// A separator defined in [RFC 2616 §2.2](https://tools.ietf.org/html/rfc2616#section-2.2)
  public var isHTTPSeparator: Bool { _isHorizontalTab || _isSpace || "()<>@,;:\\\"/[]?={}".unicodeScalars.contains(self) }

  public var isHTTPToken: Bool { isASCII && !_isControl && !isHTTPSeparator }

  public var isMIMETypeToken: Bool { !_isContentTypeValueSpecial && "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~".unicodeScalars.contains(self) }

  public var isAllowedInCookieValue: Bool { "!#$%&'()*+-./0123456789:<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~".unicodeScalars.contains(self) }

  public var isAllowedInURLUser: Bool { "!$&'()*+,-.0123456789;=ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~".unicodeScalars.contains(self) }

  public var isAllowedInURLPassword: Bool { "!$&'()*+,-.0123456789;=ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~".unicodeScalars.contains(self) }

  public var isAllowedInURLHost: Bool { "!$&'()*+,-.0123456789:;=ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~".unicodeScalars.contains(self) }

  public var isAllowedInURLPath: Bool { "!$&'()*+,-./0123456789:=@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~".unicodeScalars.contains(self) }

  public var isAllowedInURLQuery: Bool { "!$&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~".unicodeScalars.contains(self) }

  public var isAllowedInURLFragment: Bool { "!$&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~".unicodeScalars.contains(self) } 
}
