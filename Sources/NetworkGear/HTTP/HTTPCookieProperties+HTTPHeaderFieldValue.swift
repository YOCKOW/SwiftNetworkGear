/* *************************************************************************************************
 CookieProperties+HeaderFieldValue.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

private struct _SetCookieHeaderFieldValueParser<Input>: StringParser,
                                                        _UTF8Parser where Input: StringProtocol {
  typealias Output = HTTPCookieProperties

  let string: Input
  let utf8: Input.UTF8View
  let url: URL?
  let removingPercentEncoding: Bool

  init(input: Input, url: URL?, removingPercentEncoding: Bool) {
    self.string = input
    self.utf8 = input.utf8
    self.url = url
    self.removingPercentEncoding = removingPercentEncoding
  }

  init(input: Input) {
    self.init(input: input, url: nil, removingPercentEncoding: true)
  }

  private struct _NameParser: StringParser, _UTF8Parser {
    typealias Output = Input.SubSequence.SubSequence
    let string: Input.SubSequence
    let utf8: Input.SubSequence.UTF8View
    init(input: Input.SubSequence) {
      self.string = input
      self.utf8 = input.utf8
    }
    func parse() -> (output: Output, endIndex: Input.Index)? {
      var index = utf8.startIndex
      guard let name = self.parseString(from: &index, while: \._isAvailableInCookieName) else {
        return nil
      }
      return (name, index)
    }
  }

  private struct _ValueParser: StringParser, _UTF8Parser {
    typealias Output = Input.SubSequence.SubSequence
    let string: Input.SubSequence
    let utf8: Input.SubSequence.UTF8View
    init(input: Input.SubSequence) {
      self.string = input
      self.utf8 = input.utf8
    }
    func parse() -> (output: Output, endIndex: Input.Index)? {
      var index = utf8.startIndex
      if let value = self.parseString(from: &index, while: \._isAvailableInCookieValue) {
        return (value, index)
      }
      guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isDoubleQuotationMark) else {
        return nil
      }
      guard let value = self.parseString(from: &index, while: \._isAvailableInCookieValue) else {
        return nil
      }
      guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isDoubleQuotationMark) else {
        return nil
      }
      return (value, index)
    }
  }

  func parse() -> (output: HTTPCookieProperties, endIndex: Input.Index)? {
    // Reference: https://datatracker.ietf.org/doc/html/rfc6265#section-4.1

    var index = utf8.startIndex

    guard let rawName = _NameParser.parse(string, from: &index) else {
      return nil
    }
    guard let name = removingPercentEncoding ? rawName.removingPercentEncoding : rawName._string else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isEqualSign) else {
      return nil
    }

    guard let rawValue = _ValueParser.parse(string, from: &index) else {
      return nil
    }
    guard let value = removingPercentEncoding ? rawValue.removingPercentEncoding : rawValue._string else {
      return nil
    }

    let now = Date()
    var properties = HTTPCookieProperties([:])
    properties.name = name
    properties.value = value
    properties.creationDate = now
    properties.lastAccessDate = now



    return (properties, index)
  }
}


private func _attributes<S>(_ string: S) -> [String:String] where S: StringProtocol {
  let pairs = string.components(separatedBy:";").map { String($0._trimmed) }
  return pairs.reduce(into:[:]) { (result:inout [String:String], string:String) -> Void in
    let (key, value) = string.splitOnce(separator:"=")
    result[key._trimmed.lowercased()] = value.map({ String($0._trimmed) }) ?? ""
  }
}

// Generate an instance from the value of "Set-Cookie:"
extension HTTPCookieProperties {
  private mutating func _setExpires(maxAge:String?, expires:String?, now:Date) -> Bool {
    if let maxAgeString = maxAge, let maxAge = TimeInterval(maxAgeString) {
      self.expiresDate = now.addingTimeInterval(maxAge)
      self.persistent = true
      return true
    }
    
    if let  expiresString = expires {
      guard let date = Date(cookieDateString:expiresString) else { return false }
      self.expiresDate = date
      self.persistent = true
      return true
    }
    
    // No expiration was given...
    self.expiresDate = nil
    self.persistent = false
    return true
  }
  
  private mutating func __setHostOnlyToTrue(requestHost:URL.Host) {
    // Host-Only-Flag is true when:
    //   * There is no attribute named "Domain",
    //   * The value of "Domain" is an IP Address, or
    //   * The value of "Domain" is the public suffix and is equal to request host-name
    self.domain = requestHost.description
    self.hostOnly = true
  }
  private mutating func _setDomain(domain:String?, requestHost:URL.Host) -> Bool {
    guard let responseDomainString = domain else {
      self.__setHostOnlyToTrue(requestHost:requestHost)
      return true
    }
    
    let responseHost = URL.Host(string:responseDomainString)
    if responseHost.isIPAddress {
      guard responseHost == requestHost else { return false }
      self.__setHostOnlyToTrue(requestHost:requestHost)
      return true
    }
    
    guard let responseDomain = Domain(responseDomainString, options:.loose) else { return false }
    if responseDomain.isPublicSuffix {
      guard responseHost == requestHost else { return false }
      self.__setHostOnlyToTrue(requestHost:requestHost)
      return true
    }
    
    guard requestHost.domainMatches(responseHost) else { return false }
    self.domain = responseDomain.description
    self.hostOnly = false
    return true
  }
  
  @discardableResult
  private mutating func _setPath(path:String?, requestPath:String) -> Bool {
    if let responsePath = path {
      self.path = responsePath
      return true
    } else {
      // If there's no attribute of "path"...
      if requestPath.isEmpty || !requestPath.hasPrefix("/") {
        self.path = "/"
      } else {
        let indexOfLastSlash = requestPath.range(of:"/", options:.backwards)!.lowerBound
        if indexOfLastSlash == requestPath.startIndex {
          self.path = "/"
        } else {
          self.path = String(requestPath[requestPath.startIndex..<indexOfLastSlash])
        }
      }
    }
    return true
  }
  
  /// If `url` is nil, no validity check for domain
  internal init?(_responseHeaderFieldValue:HTTPHeaderFieldValue,
                 for url:URL? = nil,
                 removingPercentEncoding:Bool = true)
  {
    let nilableRequestHost = url?.hostComponent
    if url != nil && nilableRequestHost == nil { return nil }
    
    let now = Date()
    let string = _responseHeaderFieldValue.rawValue
    let (nameValue, nilableAttributes) = string.splitOnce(separator:";")
    guard let item = HTTPCookieItem(string:String(nameValue),
                                removingPercentEncoding:removingPercentEncoding) else
    {
      return nil
    }
    
    self.init([:])
    self.name = item.name
    self.value = item.value
    self.creationDate = now
    self.lastAccessDate = now
    
    if let attributes_string = nilableAttributes {
      let attributes = _attributes(attributes_string)
      
      self.secure = attributes["secure"] != Optional<String>.none ? true: false
      self.httpOnly = attributes["httponly"] != Optional<String>.none ? true: false
      
      // Calc. Expiration
      guard self._setExpires(maxAge:attributes["max-age"], expires:attributes["expires"], now:now)
        else { return nil }
      
      // Domain
      if url != nil {
        guard self._setDomain(domain:attributes["domain"], requestHost:nilableRequestHost!) else {
          return nil
        }
      } else {
        self.domain = attributes["domain"]
      }
      
      // Path
      self._setPath(path:attributes["path"], requestPath:url?.path ?? "/")
    }
  }
  
  /// Initialize with the value of HTTP header "Set-Cookie:"
  public init?(responseHeaderFieldValue:HTTPHeaderFieldValue,
               for url:URL,
               removingPercentEncoding:Bool = true)
  {
    self.init(_responseHeaderFieldValue:responseHeaderFieldValue,
              for:url,
              removingPercentEncoding:removingPercentEncoding)
  }
}
