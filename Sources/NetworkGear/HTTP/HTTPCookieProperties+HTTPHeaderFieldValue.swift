/* *************************************************************************************************
 CookieProperties+HeaderFieldValue.swift
   © 2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

public struct SetCookieHeaderFieldValueParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = HTTPCookieProperties

  public struct Configuration {
    /// The URL that the cookie is sent from.
    public var url: URL?

    /// A Boolean value indicating whether or not percent-encoding should be removed from
    /// the name and the value of the cookie.
    public var removingPercentEncoding: Bool

    public init(url: URL? = nil, removingPercentEncoding: Bool = true) {
      self.url = url
      self.removingPercentEncoding = removingPercentEncoding
    }
  }


  let input: Input
  let utf8: Input.UTF8View
  var configuration: Configuration?

  /// The URL that the cookie is sent from.
  public var url: URL? {
    get {
      return self.configuration?.url
    }
    set {
      var newConfig = self.configuration ?? Configuration()
      newConfig.url = newValue
      self.configuration = newConfig
    }
  }

  /// A Boolean value indicating whether or not percent-encoding should be removed from
  /// the name and the value of the cookie.
  public var removingPercentEncoding: Bool {
    get {
      return self.configuration?.removingPercentEncoding ?? true
    }
    set {
      var newConfig = self.configuration ?? Configuration()
      newConfig.removingPercentEncoding = newValue
      self.configuration = newConfig
    }
  }


  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  public init(input: Input, url: URL?, removingPercentEncoding: Bool) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = Configuration(url: url, removingPercentEncoding: removingPercentEncoding)
  }

  private typealias _SubParserInput = Input.SubSequence

  private struct _NameParser: StringParser, _UTF8Parser {
    typealias Output = _SubParserInput.SubSequence
    let input: _SubParserInput
    let utf8: _SubParserInput.UTF8View
    init(input: _SubParserInput) {
      self.input = input
      self.utf8 = input.utf8
    }
    func parse() -> (output: Output, endIndex: _SubParserInput.Index)? {
      var index = utf8.startIndex
      guard let name = self.parseString(from: &index, while: \._isAvailableInCookieName) else {
        return nil
      }
      return (name, index)
    }
  }

  private struct _ValueParser: StringParser, _UTF8Parser {
    typealias Output = _SubParserInput.SubSequence
    let input: _SubParserInput
    let utf8: _SubParserInput.UTF8View
    init(input: _SubParserInput) {
      self.input = input
      self.utf8 = input.utf8
    }
    func parse() -> (output: Output, endIndex: _SubParserInput.Index)? {
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

  private struct _AttributeValuePairParser: StringParser, _UTF8Parser {
    typealias Output = (
      name: _SubParserInput.SubSequence.SubSequence,
      value: _SubParserInput.SubSequence?
    )

    let input: _SubParserInput
    let utf8: _SubParserInput.UTF8View

    init(input: _SubParserInput) {
      self.input = input
      self.utf8 = input.utf8
    }

    func parse() -> (output: Output, endIndex: _SubParserInput.Index)? {
      var currentIndex = utf8.startIndex

      guard let name = self.parseString(
        from: &currentIndex,
        while: { !$0._isEqualSign && !$0._isSemicolon }
      ) else {
        return nil
      }

      var value: _SubParserInput.SubSequence? = nil
      if currentIndex < utf8.endIndex && utf8[currentIndex]._isEqualSign {
        utf8.formIndex(after: &currentIndex)
        value = self.parseString(from: &currentIndex, while: { !$0._isSemicolon })
      }
      return ((name: name._trimmed, value: value), currentIndex)
    }
  }

  public mutating func parse() -> (output: HTTPCookieProperties, endIndex: Input.Index)? {
    // Reference: https://datatracker.ietf.org/doc/html/rfc6265#section-4.1

    var currentIndex = utf8.startIndex

    guard let rawName = _NameParser.parse(input, from: &currentIndex) else {
      return nil
    }
    guard let name = removingPercentEncoding ? rawName.removingPercentEncoding : rawName._string else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isEqualSign) else {
      return nil
    }

    guard let rawValue = _ValueParser.parse(input, from: &currentIndex) else {
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

    func __parseSeparator() -> Bool {
      _ = self.parseHTTPWhitespaces(from: &currentIndex)
      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isSemicolon
      ) else {
        return false
      }
      _ = self.parseHTTPWhitespaces(from: &currentIndex)
      return true
    }

    var attributes: [ASCIICaseInsensitiveSubstring: _SubParserInput.SubSequence?] = [:]
    while currentIndex < utf8.endIndex {
      guard __parseSeparator() else {
        break
      }
      guard let attributePair = _AttributeValuePairParser.parse(input, from: &currentIndex) else {
        break
      }
      let ciName = ASCIICaseInsensitiveSubstring(attributePair.name)
      attributes[ciName] = attributePair.value
    }

    SET_ATTRIBUTES: do {
      properties.secure = attributes.keys.contains("Secure")
      properties.httpOnly = attributes.keys.contains("HttpOnly")

      SET_EXPIRES: do {
        if let maxAgeString = attributes["Max-Age"]??._trimmed, let maxAge = Int(maxAgeString) {
          properties.expiresDate = now.addingTimeInterval(TimeInterval(maxAge))
          properties.persistent = true
        } else if let expiresString = attributes["Expires"]??._trimmed {
          guard let date = Date(cookieDateString: expiresString) else {
            break SET_EXPIRES
          }
          properties.expiresDate = date
          properties.persistent = true
        } else {
          properties.expiresDate = nil
          properties.persistent = false
        }
      } // SET_EXPIRES

      SET_DOMAIN: do {
        if let url = self.url {
          guard let requestHost = url.hostComponent else {
            break SET_DOMAIN
          }

          func __setHostOnlyToTrue() {
            // Host-Only-Flag is true when:
            //   * There is no attribute named "Domain",
            //   * The value of "Domain" is an IP Address, or
            //   * The value of "Domain" is the public suffix and is equal to request host-name
            properties.domain = requestHost.description
            properties.hostOnly = true
          }

          guard let responseHostString = attributes["Domain"]??._trimmed._string else {
            __setHostOnlyToTrue()
            break SET_DOMAIN
          }

          let responseHost = URL.Host(string: responseHostString)
          if responseHost.isIPAddress {
            guard responseHost == requestHost else {
              return nil
            }
            __setHostOnlyToTrue()
            break SET_DOMAIN
          }

          guard let responseDomain = Domain(responseHostString, options: .loose) else {
            return nil
          }
          if responseDomain.isPublicSuffix {
            guard responseHost == requestHost else {
              return nil
            }
            __setHostOnlyToTrue()
            break SET_DOMAIN
          }

          guard requestHost.domainMatches(responseHost) else {
            return nil
          }
          properties.domain = responseDomain.description
          properties.hostOnly = false
        } else { // `url` is nil.
          properties.domain = attributes["Domain"]??._trimmed._string
        }
      } // SET_DOMAIN

      SET_PATH: do {
        let requestPath = self.url?.path() ?? "/"
        if let responsePath = attributes["Path"]??._trimmed._string {
          properties.path = responsePath
          break SET_PATH
        }

        // If there's no attribute of "path"...
        if requestPath.isEmpty || !requestPath.hasPrefix("/") {
          properties.path = "/"
        } else {
          let requestPathUTF8 = requestPath.utf8
          let lastIndexOfSlash = requestPathUTF8.lastIndex(where: \._isSlash)!
          if lastIndexOfSlash == requestPathUTF8.startIndex {
            properties.path = "/"
          } else {
            properties.path = requestPath[..<lastIndexOfSlash]._string
          }
        }
      } // SET_PATH
    } // SET_ATTRIBUTES

    return (properties, currentIndex)
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
  /// If `url` is nil, no validity check for domain
  internal init?(
    _responseHeaderFieldValue value: HTTPHeaderFieldValue,
    for url: URL? = nil,
    removingPercentEncoding: Bool = true
  ) {
    var parser = SetCookieHeaderFieldValueParser<String>(
      input: value.rawValue,
      url: url,
      removingPercentEncoding: removingPercentEncoding
    )
    guard let (properties, _) = parser.parse() else {
      return nil
    }
    self = properties
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
