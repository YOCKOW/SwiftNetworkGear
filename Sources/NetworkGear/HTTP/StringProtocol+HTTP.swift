/***************************************************************************************************
 StringProtocol+HTTP.swift
   © 2017-2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

private typealias _U8CodeSet = Set<Unicode.UTF8.CodeUnit>
private extension _U8CodeSet {
  init(_ string: String) {
    assert(!string.isEmpty)
    self = string.utf8.reduce(into: []) {
      assert($1 <= 0x7F)
      $0.insert($1)
    }
  }

  func union(_ string: any StringProtocol) -> _U8CodeSet {
    let utf8 = string.utf8
    assert(utf8.allSatisfy({ $0 <= 0x7F }))
    return self.union(utf8)
  }
}

/// `ALPHA` defined in [RFC 5234](https://datatracker.ietf.org/doc/html/rfc5234#appendix-B.1).
private let _ALPHA = _U8CodeSet(0x41...0x5A).union(0x61...0x7A)

/// `DIGIT` defined in [RFC 5234](https://datatracker.ietf.org/doc/html/rfc5234#appendix-B.1).
private let _DIGIT = _U8CodeSet(0x30...0x39)

private let _HEXDIG = _DIGIT.union("ABCDEFabcdef")

/// `tchar` defined in [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#section-5.6.2).
private let _tchar = _U8CodeSet("!#$%&'*+-.^_`|~").union(_DIGIT).union(_ALPHA)

/// `tspecials` defined in [RFC 2045](https://datatracker.ietf.org/doc/html/rfc2045).
private let _tspecials = _U8CodeSet("()<>@,;:\\\"/[]?=")

/// `separators` defined in [RFC 2616](https://datatracker.ietf.org/doc/html/rfc2616#section-2.2).
private let _rfc2616Separators = _U8CodeSet("()<>@,;:\\\"/[]?={}\u{20}\u{09}")

/// `unreserved` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-2.3).
private let _unreservedInURL = _ALPHA.union(_DIGIT).union("-._~")

/// `pct-encoded` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-2.1).
private let _percentEncodedInURL = _HEXDIG.union("%")

/// `sub-delims` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-2.2).
private let _subDelimiterInURL = _U8CodeSet("!$&'()*+,;=")

/// Just for backward compatibility
///
/// See [RFC 1738](https://datatracker.ietf.org/doc/html/rfc1738).
private enum _obsoleted_RFC1738 {
  static let safe = _U8CodeSet("$-_.+")
  static let extra = _U8CodeSet("!*'(),")
  static let unreserved = _ALPHA.union(_DIGIT).union(safe).union(extra)
  static let uchar = unreserved.union(_percentEncodedInURL)
  static let password = uchar.union(";?&=")
}

/// `IPv4address` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2).
private let _ipv4Address = _DIGIT.union(".")

/// `IPv6address` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2).
private let _ipv6Address = _ipv4Address.union(":")

/// `IPvFuture` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2).
private let _ipvFutureAddress = _U8CodeSet("v.:").union(_HEXDIG).union(_unreservedInURL).union(_subDelimiterInURL)

/// `IP-literal` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2).
private let _ipLiteral = _ipv6Address.union(_ipvFutureAddress).union("[]")

/// `reg-name` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2).
private let _regName = _unreservedInURL.union(_percentEncodedInURL).union(_subDelimiterInURL)

/// `pchar` defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2).
private let _pchar = _unreservedInURL.union(_percentEncodedInURL).union(_subDelimiterInURL).union(":@")

extension Unicode.UTF8.CodeUnit {
  /// `TAB`
  @inlinable
  internal var _isHorizontalTab: Bool { self == 0x09 }

  /// `Space`
  @inlinable
  internal var _isSpace: Bool { self == 0x20 }

  /// Whitespace used for `OWS`(optional whitespace) or `RWS`(required whitespace).
  @inlinable
  internal var _isHTTPWhitespace: Bool { _isSpace || _isHorizontalTab }

  /// `"`
  @inlinable
  internal var _isDoubleQuotationMark: Bool { self == 0x22 }

  /// `,`
  @inlinable
  internal var _isComma: Bool { self == 0x2C }

  /// `=`
  @inlinable
  internal var _isEqualSign: Bool { self == 0x3D }

  @inlinable
  internal var _isBackslash: Bool { self == 0x5C }

  /// Control character
  @inlinable
  internal var _isControl: Bool { self <= 0x1F || self == 0x7F }

  /// Visible Character
  @inlinable
  internal var _isVisible: Bool { 0x21 <= self && self <= 0x7E }

  /// DIGIT
  @inlinable
  internal var _isDigit: Bool { 0x30 <= self && self <= 0x39 }

  /// `obs-text` defined in [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#section-5.5).
  @inlinable
  internal var _isHTTPObsoleted: Bool {
    return 0x80 <= self // && self <= 0xFF
  }

  /// `token`
  internal var _isAvailableInHTTPToken: Bool { _tchar.contains(self) }

  /// `tspecials` defined in [RFC 2045](https://datatracker.ietf.org/doc/html/rfc2045).
  private var _isContentTypeValueSpcial: Bool { _tspecials.contains(self) }

  /// Returns the Boolean value whether or not the value is available in HTTP header field name.
  ///
  /// See: [RFC 9110 §5.1](https://datatracker.ietf.org/doc/html/rfc9110#section-5.1).
  internal var _isAvailableInHTTPHeaderFieldName: Bool { _isAvailableInHTTPToken }


  /// Returns the Boolean value whether or not the value is available in HTTP header field values.
  ///
  /// See: [RFC 9110 §5.5](https://datatracker.ietf.org/doc/html/rfc9110#section-5.5).
  internal var _isAvailableInHTTPHeaderFieldValue: Bool { _isVisible || _isSpace || _isHorizontalTab }

  /// Returns the Boolean value whether or not the value is available in HTTP header field values
  /// as the first character.
  ///
  /// See: [RFC 9110 §5.5](https://datatracker.ietf.org/doc/html/rfc9110#section-5.5).
  internal var _isAvailableAtFirstInHTTPHeaderFieldValue: Bool { _isVisible }

  /// `qdtext` defined in [RFC 9110 §5.6.4](https://datatracker.ietf.org/doc/html/rfc9110#section-5.6.4).
  @inlinable
  internal var _isAvailableInHTTPHeaderFieldValueQuotedText: Bool {
    if _isHorizontalTab || _isSpace {
      return true
    }
    switch self {
    case 0x21, 0x23...0x5B, 0x5D...0x7E:
      return true
    default:
      #if HTTP_ALLOW_OBSOLTED_TEXT
      return _isHTTPObsoleted
      #else
      return false
      #endif
    }
  }

  /// Character following `\` in `quoted-pair`.
  ///
  /// See: [RFC 9110 §5.6.4](https://datatracker.ietf.org/doc/html/rfc9110#section-5.6.4).
  @inlinable
  internal var _canBeEscapedInQuotedText: Bool {
    if _isHorizontalTab || _isSpace || _isVisible {
      return true
    }
    #if HTTP_ALLOW_OBSOLTED_TEXT
    return _isHTTPObsoleted
    #else
    return false
    #endif
  }

  /// Returns the Boolean value whether or not the value is available in `opaque-tag` defined in
  /// [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#section-8.8.3).
  internal var _isAvailableInHTTPOpaqueTagContent: Bool {
    return self == 0x21 || (0x23 <= self && self <= 0x7E) || self._isHTTPObsoleted
  }

  /// Returns the Boolean value whether or not the value is available in MIME Type tokens.
  ///
  /// See: [RFC 2045 §5.1](https://datatracker.ietf.org/doc/html/rfc2045#section-5.1).
  internal var _isAvailableInMIMETypeToken: Bool {
    return self <= 0x7F && !_isSpace && !_isControl && !_isContentTypeValueSpcial
  }

  internal var _isRFC2616Separator: Bool { _rfc2616Separators.contains(self) }

  private var _isRFC2616Token: Bool {
    return self <= 0x70 && !_isControl && !_isRFC2616Separator
  }

  /// Returns the Boolean value whether or not the value is available in Cookie names.
  ///
  /// See: [RFC 6265 §4.1.1](https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.1).
  internal var _isAvailableInCookieName: Bool { _isRFC2616Token }

  /// `cookie-octet` defined in [RFC 6265](https://datatracker.ietf.org/doc/html/rfc6265).
  private var _isCookieOctet: Bool {
    return (
      self == 0x21 ||
      (0x23 <= self && self <= 0x2B) ||
      (0x2D <= self && self <= 0x3A) ||
      (0x3C <= self && self <= 0x5B) ||
      (0x5D <= self && self <= 0x7E)
    )
  }


  /// Returns the Boolean value whether or not the value is available in Cookie names.
  ///
  /// See: [RFC 6265 §4.1.1](https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.1).
  internal var _isAvailableInCookieValue: Bool { _isCookieOctet }

  /// Returns the Boolean value whether or not the value is available in user name part of URL.
  ///
  /// See: [RFC 3986 §3.2.1](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.1).
  internal var _isAvailableInURLUserName: Bool {
    return _unreservedInURL.contains(self) || _percentEncodedInURL.contains(self) || _subDelimiterInURL.contains(self)
  }

  /// Returns the Boolean value whether or not the value is available in user password part of URL.
  ///
  /// - NOTE: Use of the format "user:password" in the userinfo field is deprecated.
  internal var _isAvailableInURLUserPassword: Bool {
    return _obsoleted_RFC1738.password.contains(self)
  }

  /// Returns the Boolean value whether or not the value is available in `host` part of URL.
  ///
  /// See: [RFC 3986 §3.2.2](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2).
  internal var _isAvailableInURLHost: Bool {
    return _ipLiteral.contains(self) || _ipv4Address.contains(self) || _regName.contains(self)
  }

  /// Returns the Boolean value whether or not the value is available in `port` part of URL.
  ///
  /// See: [RFC 3986 §3.2.3](https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.3).
  internal var _isAvailableInURLPort: Bool { _isDigit }

  /// Returns the Boolean value whether or not the value is available in `path` part of URL.
  ///
  /// See: [RFC 3986 §3.3](https://datatracker.ietf.org/doc/html/rfc3986#section-3.3).
  internal var _isAvailableInURLPath: Bool {
    return self == 0x2F /* "/" */ || _pchar.contains(self)
  }

  /// Returns the Boolean value whether or not the value is available in `query` part of URL.
  ///
  /// See: [RFC 3986 §3.4](https://datatracker.ietf.org/doc/html/rfc3986#section-3.4).
  internal var _isAvailableInURLQuery: Bool {
    return self == 0x2F /* "/" */ || self == 0x3F /* "?" */ || _pchar.contains(self)
  }

  /// Returns the Boolean value whether or not the value is available in `fragment` part of URL.
  ///
  /// See: [RFC 3986 §3.5](https://datatracker.ietf.org/doc/html/rfc3986#section-3.5).
  internal var _isAvailableInURLFragment: Bool {
    return self == 0x2F /* "/" */ || self == 0x3F /* "?" */ || _pchar.contains(self)
  }
}

extension StringProtocol {
  /// Returns the Boolean value that indicates whether or not the string can be a valid HTTP method.
  public var isLiterallyAcceptableForHTTPMethod: Bool {
    return !self.isEmpty && self.utf8.allSatisfy(\._isAvailableInHTTPToken)
  }
}

@available(*, deprecated, message: "Use functions/properties of each type instead.")
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
