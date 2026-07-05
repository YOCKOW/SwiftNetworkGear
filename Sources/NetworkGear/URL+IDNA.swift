/***************************************************************************************************
 URL+IDNA.swift
   © 2017-2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import Foundation

/// A parser to parse a URL allowing an international string for its host part such as
/// "`https://にっぽん。ＪＰ/☕︎.cgi?杯=2#MyCoffee`".
///
/// - Note: The string must start with a scheme followed by "://".
public struct InternationalURLStringParser<Input>: StringParser, _UTF8Parser
where Input: StringProtocol {
  public typealias Output = URLComponents

  public struct Configuration {
    /// A Boolean value indicating whether or not whitespaces are regarded as part of the URL.
    public let allowWhitespaces: Bool

    /// A Boolean value indicating whether or not newlines are regarded as part of the URL.
    public let allowNewlines: Bool

    public init(allowWhitespaces: Bool = false, allowNewlines: Bool = false) {
      self.allowWhitespaces = allowWhitespaces
      self.allowNewlines = allowNewlines
    }

    fileprivate var _isAllowedUTF8CodeUnit: (Unicode.UTF8.CodeUnit) -> Bool {
      switch (allowWhitespaces, allowNewlines) {
      case (false, false):
        return { !$0._isHTTPWhitespace && !$0._isNewline }
      case (true, false):
        return { !$0._isNewline }
      case (false, true):
        return { !$0._isHTTPWhitespace }
      case (true, true):
        return { _ in true }
      }
    }
  }

  private typealias _SchemeInput = Input.SubSequence
  private struct _SchemeParser: StringParser, _UTF8Parser {
    typealias Input = _SchemeInput
    typealias Output = _SchemeInput.SubSequence

    let input: _SchemeInput
    let utf8: _SchemeInput.UTF8View

    init(input: _SchemeInput) {
      self.input = input
      self.utf8 = input.utf8
    }

    mutating func parse() -> (output: Output, endIndex: _SchemeInput.Index)? {
      var currentIndex = self.utf8.startIndex
      guard let _ = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: \._isAlphabet
      ) else {
        return nil
      }
      _ = self.parseString(from: &currentIndex, while: \._isAvailableInURLScheme)
      return (input[..<currentIndex], currentIndex)
    }
  } // _SchemeParser

  private typealias _AuthorityInput = Input.SubSequence
  private typealias _UserInfoInput = _AuthorityInput.SubSequence
  private typealias _HostInput = _AuthorityInput.SubSequence
  private struct _Authority {
    struct UserInfo  {
      let name: _UserInfoInput.SubSequence?
      let password: _UserInfoInput.SubSequence?
      init(name: _UserInfoInput.SubSequence?, password: _UserInfoInput.SubSequence?) {
        self.name = name
        self.password = password
      }
    } // UserInfo

    typealias Port = UInt16

    let userInfo: UserInfo?
    let host: URL.Host
    let port: Port?

    init(userInfo: UserInfo?, host: URL.Host, port: UInt16?) {
      self.userInfo = userInfo
      self.host = host
      self.port = port
    }
  } // _Authority

  private struct _AuthorityParser: StringParser, _UTF8Parser {
    typealias Input = _AuthorityInput
    typealias Output = _Authority
    typealias Configuration = InternationalURLStringParser.Configuration

    private struct UserInfoParser: StringParser, _UTF8Parser {
      typealias Input = _UserInfoInput
      typealias Output = _Authority.UserInfo

      let input: _UserInfoInput
      let utf8 : _UserInfoInput.UTF8View
      init(input: _UserInfoInput) {
        self.input = input
        self.utf8 = input.utf8
      }

      mutating func parse() -> (output: Output, endIndex: _UserInfoInput.Index)? {
        var currentIndex = self.utf8.startIndex

        /// Parse a password and at sign.
        func __parseUserPassword() -> _UserInfoInput.SubSequence? {
          let originalStartIndex = currentIndex
          // Empty password allowed.
          _ = self.parseString(
            from: &currentIndex,
            while: \._isAvailableInURLUserPassword
          )
          let endIndexOfPassword = currentIndex
          guard let _ = self.readCurrentCodeUnit(
            at: &currentIndex,
            ifAllowedCodeUnit: \._isAtSign
          ) else {
            currentIndex = originalStartIndex
            return nil
          }
          return input[originalStartIndex..<endIndexOfPassword]
        } // __parseUserPassword

        if let userName = self.parseString(
          from: &currentIndex,
          while: \._isAvailableInURLUserName
        ) {
          if let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isAtSign) {
            return (
              _Authority.UserInfo(name: userName, password: nil),
              currentIndex
            )
          }
          guard let _ = self.readCurrentCodeUnit(
            at: &currentIndex,
            ifAllowedCodeUnit: \._isColon
          ) else {
            return nil
          }
          guard let password = __parseUserPassword() else {
            return nil
          }
          return (
            _Authority.UserInfo(name: userName, password: password),
            currentIndex
          )
        } else { // No user name found.
          guard let _ = self.readCurrentCodeUnit(
            at: &currentIndex,
            ifAllowedCodeUnit: \._isColon
          ) else {
            return nil
          }
          guard let password = __parseUserPassword() else {
            return nil
          }
          return (
            _Authority.UserInfo(name: nil, password: password),
            currentIndex
          )
        }
      }
    } // UserInfoParser

    private struct HostParser: StringParser, _UTF8Parser {
      typealias Input = _HostInput
      typealias Output = URL.Host
      typealias Configuration = _AuthorityParser.Configuration

      let input: _HostInput
      let utf8: _HostInput.UTF8View
      let configuration: Configuration
      init(input: _HostInput, configuration: Configuration?) {
        self.input = input
        self.utf8 = input.utf8
        self.configuration = configuration ?? .init()
      }

      mutating func parse() -> (output: Output, endIndex: _HostInput.Index)? {
        var currentIndex = self.utf8.startIndex
        if let ip = _SomeIPAddressEnclosedBySquareBracketsParser<_HostInput.SubSequence>.parse(
          input,
          from: &currentIndex
        ) {
          switch ip {
          case .ipv6Address(let ipv6):
            return (URL.Host(_ipAddress: ipv6), currentIndex)
          case .ipvFutureAddress(let ipvFuture):
            return (URL.Host(_ipvFutureAddress: ipvFuture), currentIndex)
          }
        } else if let ipv4 = IPv4AddressParser<_HostInput.SubSequence>.parse(
          input,
          from: &currentIndex
        ) {
          return (URL.Host(_ipAddress: ipv4), currentIndex)
        }

        let isAllowedByConfig = configuration._isAllowedUTF8CodeUnit
        guard let hostString = self.parseString(from: &currentIndex, while: {
          !$0._isColon && !$0._isSlash && isAllowedByConfig($0)
        }) else {
          return nil
        }
        if let domain = Domain(hostString, options: .loose) {
          return (URL.Host(_domain: domain), currentIndex)
        }
        return (URL.Host(_rawString: hostString), currentIndex)
      }
    } // HostParser

    let input: _AuthorityInput
    let utf8: _AuthorityInput.UTF8View
    let configuration: Configuration
    init(input: _AuthorityInput, configuration: Configuration?) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .init()
    }

    mutating func parse() -> (output: _Authority, endIndex: _AuthorityInput.Index)? {
      var currentIndex = self.input.startIndex

      let userInfo = UserInfoParser.parse(self.input, from: &currentIndex) // Optional

      guard let host = HostParser.parse(
        self.input,
        from: &currentIndex,
        configuration: self.configuration
      ) else {
        return nil
      }

      var port: _Authority.Port? = nil
      if let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isColon) {
        port = self.parseInt(_Authority.Port.self, from: &currentIndex)
      }

      return (_Authority(userInfo: userInfo, host: host, port: port), currentIndex)
    }
  } // _AuthorityParser

  private typealias _PathInput = Input.SubSequence
  private struct _PathParser: StringParser, _UTF8Parser, _SubstringOutputParser {
    typealias Input = _PathInput
    typealias Output = _PathInput.SubSequence
    typealias Configuration = InternationalURLStringParser.Configuration

    let input: _PathInput
    let utf8: _PathInput.UTF8View
    let configuration: Configuration

    init(input: _PathInput, configuration: Configuration?) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .init()
    }

    mutating func parse() -> _PathInput.Index? {
      var currentIndex = self.utf8.startIndex
      guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isSlash) else {
        return nil
      }
      let isAllowedByConfig = configuration._isAllowedUTF8CodeUnit
      let _ = self.parseString(from: &currentIndex, while: {
        !$0._isQuestionMark && !$0._isNumberSign && isAllowedByConfig($0)
      })
      return currentIndex
    }
  } // _PathParser

  private typealias _QueryInput = Input.SubSequence
  private struct _QueryParser: StringParser, _UTF8Parser {
    typealias Input = _QueryInput
    typealias Output = _QueryInput.SubSequence
    typealias Configuration = InternationalURLStringParser.Configuration

    let input: _QueryInput
    let utf8: _QueryInput.UTF8View
    let configuration: Configuration

    init(input: _QueryInput, configuration: Configuration?) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .init()
    }

    mutating func parse() -> (output: Output, endIndex: _QueryInput.Index)? {
      var currentIndex = self.utf8.startIndex
      let isAllowedByConfig = configuration._isAllowedUTF8CodeUnit
      guard let query = self.parseString(from: &currentIndex, while: {
        !$0._isNumberSign && isAllowedByConfig($0)
      }) else {
        return nil
      }
      return (query, currentIndex)
    }
  } // _QueryParser

  private typealias _FragmentInput = Input.SubSequence
  private struct _FragmentParser: StringParser, _UTF8Parser {
    typealias Input = _FragmentInput
    typealias Output = _FragmentInput.SubSequence
    typealias Configuration = InternationalURLStringParser.Configuration

    let input: _FragmentInput
    let utf8: _FragmentInput.UTF8View
    let configuration: Configuration

    init(input: _FragmentInput, configuration: Configuration?) {
      self.input = input
      self.utf8 = input.utf8
      self.configuration = configuration ?? .init()
    }

    mutating func parse() -> (output: Output, endIndex: _FragmentInput.Index)? {
      var currentIndex = self.utf8.startIndex
      let isAllowedByConfig = configuration._isAllowedUTF8CodeUnit
      guard let fragment = self.parseString(from: &currentIndex, while: isAllowedByConfig) else {
        return nil
      }
      return (fragment, currentIndex)
    }
  } // _FragmentParser

  let input: Input
  public var configuration: Configuration

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.configuration = configuration ?? .init()
  }

  public mutating func parse() -> (output: URLComponents, endIndex: Input.Index)? {
    var currentIndex = self.input.startIndex

    guard let scheme = _SchemeParser.parse(input, from: &currentIndex) else {
      return nil
    }

    // Consume "://"
    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isColon),
          let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isSlash),
          let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isSlash) else {
      return nil
    }

    guard let authority = _AuthorityParser.parse(
      input,
      from: &currentIndex,
      configuration: configuration
    ) else {
      return nil
    }

    var components = URLComponents()
    components.scheme = scheme._string
    components.user = authority.userInfo?.name?._string
    components.password = authority.userInfo?.password?._string
    components.host = authority.host.description
    components.port = authority.port.flatMap(Int.init)

    // Then, split "/path?query#fragment".

    if currentIndex < input.endIndex && self.utf8[currentIndex]._isSlash {
      components.path = _PathParser.parse(
        input,
        from: &currentIndex, configuration: configuration
      )!._string
    }

    if let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isQuestionMark) {
      components.query = _QueryParser.parse(
        input, from: &currentIndex, configuration: configuration
      )?._string ?? ""
    }

    if let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isNumberSign) {
      components.fragment = _FragmentParser.parse(
        input,
        from: &currentIndex,
        configuration: configuration
      )?._string ?? ""
    }

    return (components, currentIndex)
  }
}

extension URL {
  public typealias InternationalURLStringParseStrategy<S> = InternationalURLStringParser<S>.Configuration where S: StringProtocol

  /// Initialize `URL` with an international string such as "`https://にっぽん。ＪＰ/☕︎.cgi?杯=2#MyCoffee`"
  /// - parameter internationalString: A string containing non-ASCII characters.
  /// - returns: If `string` can be parsed, an instance of `URL` is returned, otherwise `nil`.
  public init?<S>(
    internationalString string: S,
    strategy: InternationalURLStringParseStrategy<S>? = nil
  ) where S: StringProtocol {
    var parser = InternationalURLStringParser<S>(input: string, configuration: strategy)
    guard let (components, endIndex) = parser.parse(),
          endIndex == string.endIndex,
          let url = components.url else {
      return nil
    }
    self = url
  }
}
