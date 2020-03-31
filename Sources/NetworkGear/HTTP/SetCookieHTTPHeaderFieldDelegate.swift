/* *************************************************************************************************
 SetCookieHeaderFieldDelegate.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// Represents "Set-Cookie:"
public struct SetCookieHTTPHeaderFieldDelegate: HTTPHeaderFieldDelegate {
  public struct Cookie: HTTPHeaderFieldValueConvertible {
    private var _cookie: AnyHTTPCookie
    fileprivate init<C>(_ cookie:C) where C:RFC6265Cookie {
      self._cookie = AnyHTTPCookie(cookie)
    }
    
    public init?(_ value: HTTPHeaderFieldValue) {
      self.init(value, userInfo: nil)
    }
    
    public init?(_ value: HTTPHeaderFieldValue, userInfo: [AnyHashable: Any]?) {
      guard let properties: HTTPCookieProperties = ({
        if case let url as URL = userInfo?["url"] {
          return HTTPCookieProperties(responseHeaderFieldValue: value, for: url)
        } else {
          return HTTPCookieProperties(_responseHeaderFieldValue: value)
        }
      })() else { return nil }
      guard let cookie = AnyHTTPCookie(properties:properties) else { return nil }
      self.init(cookie)
    }
    
    public var httpHeaderFieldValue: HTTPHeaderFieldValue {
      return self._cookie.responseHeaderFieldValue()!
    }
  }
  public typealias HTTPHeaderFieldValueSource = Cookie
  
  public static var name: HTTPHeaderFieldName { return .setCookie }
  public static var type: HTTPHeaderField.PresenceType { return .duplicable }
  
  public var source:Cookie
  public init(_ source:Cookie) {
    self.source = source
  }
  
  /// Initialize with `cookie`
  public init<C>(cookie:C) where C:RFC6265Cookie {
    self.init(Cookie(cookie))
  }
}

extension SetCookieHTTPHeaderFieldDelegate.Cookie: RFC6265Cookie {
  public var name: String { return self._cookie.name }
  public var value: String { return self._cookie.value }
  public var domain: String { return self._cookie.domain }
  public var path: String { return self._cookie.path }
  public var creationDate: Date? { return self._cookie.creationDate }
  public var expiresDate: Date? { return self._cookie.expiresDate }
  public var lastAccessDate: Date? { return self._cookie.lastAccessDate }
  public var isPersistent: Bool { return self._cookie.isPersistent }
  public var isHostOnly: Bool { return self._cookie.isHostOnly }
  public var isSecure: Bool { return self._cookie.isSecure }
  public var isHTTPOnly: Bool { return self._cookie.isHTTPOnly }
}
