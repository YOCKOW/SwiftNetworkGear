/***************************************************************************************************
 IPAddress.swift
   © 2017-2019,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CNetworkGear

/**
 
 # IPAddress
 Represents IP Address.
 
 */
public enum IPAddress: Sendable {
  case v4(UInt8, UInt8, UInt8, UInt8)
  case v6(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
          UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}

extension IPAddress {
  public init<T>(_ cIPAddress: T) where T: CIPAddress {
    switch type(of: cIPAddress).size {
    case 4:
      self = cIPAddress.withUnsafeBufferPointer {
        return .v4($0[0], $0[1], $0[2], $0[3])
      }
    case 16:
      self = cIPAddress.withUnsafeBufferPointer {
        return .v6($0[0], $0[1],  $0[2],  $0[3],  $0[4],  $0[5],  $0[6], $0[7],
                   $0[8], $0[9], $0[10], $0[11], $0[12], $0[13], $0[14], $0[15])
      }
    default:
      fatalError("Unexpected IPAddress.")
    }
  }
}

/// Some possible IP address in the future.
///
/// - String Syntax: `"v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )`
public struct IPvFutureAddress: Sendable, CustomStringConvertible, Equatable, Hashable {
  public let version: Int
  public let stringRepresentation: String

  public var description: String {
    return "v\(String(version, radix: 16)).\(stringRepresentation)"
  }

  internal init(version: Int, _validatedStringRepresentation stringRepresentation: String) {
    self.version = version
    self.stringRepresentation = stringRepresentation
  }

  public init?<S>(version: Int, stringRepresentation: S) where S: StringProtocol {
    guard stringRepresentation.utf8.allSatisfy(\._isAvailableInIPvFutureStringRepresentation) else {
      return nil
    }
    self.init(version: version, _validatedStringRepresentation: stringRepresentation._string)
  }
}

public struct IPv4AddressParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = IPAddress

  let input: Input
  let utf8: Input.UTF8View
  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: IPAddress, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    guard let u0 = self.parseInt(UInt8.self, from: &currentIndex, maxNumberOfDigits: 3) else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod) else {
      return nil
    }
    guard let u1 = self.parseInt(UInt8.self, from: &currentIndex, maxNumberOfDigits: 3) else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod) else {
      return nil
    }
    guard let u2 = self.parseInt(UInt8.self, from: &currentIndex, maxNumberOfDigits: 3) else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod) else {
      return nil
    }
    guard let u3 = self.parseInt(UInt8.self, from: &currentIndex, maxNumberOfDigits: 3) else {
      return nil
    }

    return (.v4(u0, u1, u2, u3), currentIndex)
  }
}

private protocol _EnclosedBySquareBracketsParser: _UTF8Parser {
  mutating func _parseContent(from startIndex: Input.UTF8View.Index) -> (content: Output, endIndex: Input.Index)?
}
extension _EnclosedBySquareBracketsParser {
  mutating func _parseContentEnclosedBySquareBrackets(
    from startIndex: Input.UTF8View.Index? = nil
  ) -> (content: Output, endIndex: Input.Index)? {
    var currentIndex = startIndex ?? self.utf8.startIndex
    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isLeftSquareBracket
    ) else {
      return nil
    }
    guard let (content, contentEndIndex) = self._parseContent(from: currentIndex) else {
      return nil
    }
    currentIndex = contentEndIndex
    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: \._isRightSquareBracket
    ) else {
      return nil
    }
    return (content, currentIndex)
  }
}

public struct IPv6AddressParser<Input>: StringParser, _UTF8Parser, _EnclosedBySquareBracketsParser
where Input: StringProtocol {
  public typealias Output = IPAddress

  public struct Configuration {
    public enum SquareBracketsParseStrategy {
      /// Square brackets are always reauired.
      case required

      /// The address should not enclosed by square brackets.
      case unacceptable

      /// Square brackets are optional. (Default)
      case auto
    }

    public var squareBrackets: SquareBracketsParseStrategy

    public init(squareBrackets: SquareBracketsParseStrategy = .auto) {
      self.squareBrackets = squareBrackets
    }
  }

  let input: Input
  let utf8: Input.UTF8View

  public var configuration: Configuration?

  public var squareBrackets: Configuration.SquareBracketsParseStrategy {
    get {
      return configuration?.squareBrackets ?? .auto
    }
    set {
      var newConfig = self.configuration ?? .init()
      newConfig.squareBrackets = newValue
      self.configuration = newConfig
    }
  }

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  public init(input: Input, squareBrackets: Configuration.SquareBracketsParseStrategy) {
    self.init(input: input, configuration: .init(squareBrackets: squareBrackets))
  }

  private static func _convertH16String<S>(_ h16String: S) -> (UInt8, UInt8)?
  where S: StringProtocol {
    guard let h16 = UInt16(h16String, radix: 16) else {
      return nil
    }
    return (UInt8(h16 >> 8), UInt8(h16 & 0xFF))
  }

  /// A parser for 16 bits of address represented in hexadecimal
  private struct _H16Parser<H16Input>: StringParser, _UTF8Parser where H16Input: StringProtocol {
    typealias Output = (UInt8, UInt8)

    let input: H16Input
    let utf8: H16Input.UTF8View
    init(input: H16Input) {
      self.input = input
      self.utf8 = input.utf8
    }

    mutating func parse() -> (output: Output, endIndex: H16Input.Index)? {
      var currentIndex = self.utf8.startIndex
      guard
        let h16String = self.parseString(
          from: &currentIndex,
          minCount: 1, maxCount: 4,
          while: \._isHexDigit
        ),
        let output = _convertH16String(h16String)
      else {
        return nil
      }
      return (output, currentIndex)
    }
  } // _H16Parser

  /// Find `h16` or IPv4 Address.
  ///
  /// - Examples:
  ///     + `12AB` → `h16`
  ///     + `123` → `h16`
  ///     + `123.45` → `h16` where `endIndex` is the index of `.`
  ///     + `127.0.0.1` → `ipv4Address`
  private struct _H16OrIPv4AddressParser<H16IPv4Input>: StringParser, _UTF8Parser
  where H16IPv4Input: StringProtocol {
    enum Output {
      case h16(UInt8, UInt8)
      case ipv4Address(UInt8, UInt8, UInt8, UInt8)
    }

    let input: H16IPv4Input
    let utf8: H16IPv4Input.UTF8View
    init(input: H16IPv4Input) {
      self.input = input
      self.utf8 = input.utf8
    }

    mutating func parse() -> (output: Output, endIndex: H16IPv4Input.Index)? {
      var currentIndex = self.utf8.startIndex
      var h16StringByteCount = 0
      guard let h16 = self.parseString(
        from: &currentIndex,
        minCount: 1,
        maxCount: 4,
        count: &h16StringByteCount,
        while: \._isHexDigit
      ) else {
        return nil
      }
      let endIndexOfH16 = currentIndex

      // For example, `123` can be parsed as `h16` and also as `UInt8`.
      if h16StringByteCount < 4,
         let u0 = UInt8(h16),
         let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod),
         let u1 = self.parseInt(UInt8.self, from: &currentIndex, maxNumberOfDigits: 3),
         let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod),
         let u2 = self.parseInt(UInt8.self, from: &currentIndex, maxNumberOfDigits: 3),
         let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod),
         let u3 = self.parseInt(UInt8.self, from: &currentIndex, maxNumberOfDigits: 3) {
        return (.ipv4Address(u0, u1, u2, u3), currentIndex)
      }

      guard let u8tuple = _convertH16String(h16) else {
        return nil
      }
      return (.h16(u8tuple.0, u8tuple.1), endIndexOfH16)
    }
  }

  /// Parser for `ls32`
  private struct _LS32Parser<LS32Input>: StringParser where LS32Input: StringProtocol {
    enum Output {
      case twoH16s(UInt8, UInt8, UInt8, UInt8)
      case ipv4Address(UInt8, UInt8, UInt8, UInt8)
      case failedButOneH16Found(UInt8, UInt8)
    }

    struct Configuration {
      let allowFailureIfOneH16Found: Bool
      init(allowFailureIfOneH16Found: Bool) {
        self.allowFailureIfOneH16Found = allowFailureIfOneH16Found
      }
    }

    let input: LS32Input
    let configuration: Configuration?
    var allowFailureIfOneH16Found: Bool {
      return self.configuration?.allowFailureIfOneH16Found ?? true
    }

    init(input: LS32Input, configuration: Configuration?) {
      self.input = input
      self.configuration = configuration
    }

    init(input: LS32Input, allowFailureIfOneH16Found: Bool) {
      self.input = input
      self.configuration = .init(allowFailureIfOneH16Found: allowFailureIfOneH16Found)
    }

    mutating func parse() -> (output: Output, endIndex: LS32Input.Index)? {
      guard let h16OrIPv4Result = _H16OrIPv4AddressParser<LS32Input>.parse(input) else {
        return nil
      }

      switch h16OrIPv4Result.output {
      case let .ipv4Address(u0, u1, u2, u3):
        return (.ipv4Address(u0, u1, u2, u3), h16OrIPv4Result.endIndex)
      case let .h16(u0, u1):
        typealias _OneMoreColonH16Parser = ColonFollowedBy<
          _H16Parser<LS32Input.SubSequence.SubSequence>,
          LS32Input.SubSequence
        >

        var currentIndex = h16OrIPv4Result.endIndex
        guard let secondH16 = _OneMoreColonH16Parser.parse(input, from: &currentIndex) else {
          if allowFailureIfOneH16Found {
            return (.failedButOneH16Found(u0, u1), h16OrIPv4Result.endIndex)
          } else {
            return nil
          }
        }
        return (.twoH16s(u0, u1, secondH16.0, secondH16.1), currentIndex)
      }
    }
  }

  /// A parser for `"::"`.
  private struct _DoubleColonParser<DoubleColonInput>: StringParser,  _UTF8Parser, _SubstringOutputParser
  where DoubleColonInput: StringProtocol {
    let input: DoubleColonInput
    let utf8: DoubleColonInput.UTF8View
    init(input: DoubleColonInput) {
      self.input = input
      self.utf8 = input.utf8
    }

    mutating func parse() -> DoubleColonInput.Index? {
      var currentIndex = self.utf8.startIndex
      guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isColon),
            let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isColon) else {
        return nil
      }
      return currentIndex
    }
  } // _DoubleColonParser

  mutating func _parseContent(
    from startIndex: Input.UTF8View.Index
  ) -> (content: Output, endIndex: Input.Index)? {
    //  # IMPLEMENTATION NOTE
    //
    //  ## Address Patterns (quoted from RFC 3986):
    //
    //  ⑴                            6( h16 ":" ) ls32
    //  ⑵                       "::" 5( h16 ":" ) ls32
    //  ⑶ [               h16 ] "::" 4( h16 ":" ) ls32
    //  ⑷ [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
    //  ⑸ [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
    //  ⑹ [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
    //  ⑺ [ *4( h16 ":" ) h16 ] "::"              ls32
    //  ⑻ [ *5( h16 ":" ) h16 ] "::"              h16
    //  ⑼ [ *6( h16 ":" ) h16 ] "::"
    //
    //  ls32        = ( h16 ":" h16 ) / IPv4address
    //  h16         = 1*4HEXDIG

    typealias _SubInput = Input.SubSequence
    typealias _ColonH16Parser = ColonFollowedBy<_H16Parser<_SubInput.SubSequence>, _SubInput>
    typealias _ColonLS32Parser = ColonFollowedBy<_LS32Parser<_SubInput.SubSequence>, _SubInput>

    let ipv6Bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
    defer {
      ipv6Bytes.deallocate()
    }
    ipv6Bytes.initialize(repeating: 0, count: 16)

    var ipv6Address: IPAddress {
      return .v6(
        ipv6Bytes[0], ipv6Bytes[1], ipv6Bytes[2], ipv6Bytes[3],
        ipv6Bytes[4], ipv6Bytes[5], ipv6Bytes[6], ipv6Bytes[7],
        ipv6Bytes[8], ipv6Bytes[9], ipv6Bytes[10], ipv6Bytes[11],
        ipv6Bytes[12], ipv6Bytes[13], ipv6Bytes[14], ipv6Bytes[15]
      )
    }

    var u8Count: (beforeDoubleColon: Int, afterDoubleColon: Int) = (0, 0)
    var currentIndex = startIndex

    if let firstH16 = _H16Parser<_SubInput>.parse(input, from: &currentIndex) {
      func __append(bytes: UInt8...) {
        for byte in bytes {
          assert(u8Count.beforeDoubleColon < 16)
          ipv6Bytes[u8Count.beforeDoubleColon] = byte
          u8Count.beforeDoubleColon += 1
        }
      }
      __append(bytes: firstH16.0, firstH16.1)

      PARSE_COLON_H16: while let nextH16 = _ColonH16Parser.parse(input, from: &currentIndex) {
        __append(bytes: nextH16.0, nextH16.1)

        assert(u8Count.beforeDoubleColon % 2 == 0)
        switch u8Count.beforeDoubleColon {
        case ..<12:
          continue
        case 12:
          guard let ls32Result = _ColonLS32Parser.parse(
            input,
            from: &currentIndex,
            configuration: .init(allowFailureIfOneH16Found: true)
          ) else {
            break PARSE_COLON_H16
          }
          switch ls32Result {
          case .twoH16s(let u0, let u1, let u2, let u3),
              .ipv4Address(let u0, let u1, let u2, let u3):
            // Pattern ⑴
            __append(bytes: u0, u1, u2, u3)
            assert(u8Count.beforeDoubleColon == 16)
            return (ipv6Address, currentIndex)
          case .failedButOneH16Found(let u0, let u1):
            __append(bytes: u0, u1)
            break PARSE_COLON_H16
          }
        default:
          fatalError("Unexpected count?!")
        }
      }
    }
    assert(u8Count.beforeDoubleColon < 15 && u8Count.beforeDoubleColon % 2 == 0)

    // ⑴ must have been already handled.
    // Then, "::" must follows.
    guard let _ = _DoubleColonParser<_SubInput>.parse(input, from: &currentIndex) else {
      return nil
    }

    // Parse the rest (after "::")

    let restU8MaxCount = 16 - u8Count.beforeDoubleColon
    let ipv6BytesAfterDoubleColon = UnsafeMutablePointer<UInt8>.allocate(capacity: restU8MaxCount)
    defer {
      ipv6BytesAfterDoubleColon.deallocate()
    }
    ipv6BytesAfterDoubleColon.initialize(repeating: 0, count: restU8MaxCount)

    var endIndex = currentIndex
    PARSE_REST_COMPONENTS: while u8Count.afterDoubleColon < restU8MaxCount {
      func __append(bytes: UInt8...) {
        for byte in bytes {
          assert(u8Count.afterDoubleColon < restU8MaxCount)
          ipv6BytesAfterDoubleColon[u8Count.afterDoubleColon] = byte
          u8Count.afterDoubleColon += 1
        }
      }

      assert(restU8MaxCount % 2 == 0)
      let restU8Count = restU8MaxCount - u8Count.afterDoubleColon
      switch restU8Count {
      case 2:
        if let h16 = _H16Parser<_SubInput>.parse(input, from: &currentIndex) {
          __append(bytes: h16.0, h16.1)
          endIndex = currentIndex
        }
        break PARSE_REST_COMPONENTS
      case 4...:
        assert(restU8Count <= 16)
        guard let h16OrIPv4 = _H16OrIPv4AddressParser<_SubInput>.parse(
          input, from: &currentIndex
        ) else {
          break PARSE_REST_COMPONENTS
        }
        endIndex = currentIndex
        switch h16OrIPv4 {
        case .h16(let u0, let u1):
          __append(bytes: u0, u1)
        case .ipv4Address(let u0, let u1, let u2, let u3):
          __append(bytes: u0, u1, u2, u3)
          break PARSE_REST_COMPONENTS
        }
      default:
        fatalError("Unexpected count?!")
      }
      guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isColon) else {
        break
      }
    }

    let startIndexOfU8AfterDoubleColon = u8Count.beforeDoubleColon + (restU8MaxCount - u8Count.afterDoubleColon)
    for ii in startIndexOfU8AfterDoubleColon..<16 {
      ipv6Bytes[ii] = ipv6BytesAfterDoubleColon[ii - startIndexOfU8AfterDoubleColon]
    }

    return (ipv6Address, endIndex)
  }

  public mutating func parse() -> (output: IPAddress, endIndex: Input.Index)? {
    switch self.squareBrackets {
    case .required:
      return self._parseContentEnclosedBySquareBrackets() as (Output, Input.Index)?
    case .unacceptable:
      return self._parseContent(from: self.utf8.startIndex) as (Output, Input.Index)?
    case .auto:
      return (
        self._parseContentEnclosedBySquareBrackets() ??
        self._parseContent(from: self.utf8.startIndex)
      ) as (Output, Input.Index)?
    }
  }
}

public struct IPvFutureAddressParser<Input>: StringParser, _UTF8Parser, _EnclosedBySquareBracketsParser
where Input: StringProtocol {
  public typealias Output = IPvFutureAddress

  public struct Configuration {
    public typealias SquareBracketsParseStrategy = IPv6AddressParser<Input>.Configuration.SquareBracketsParseStrategy

    public var squareBrackets: SquareBracketsParseStrategy

    public init(squareBrackets: SquareBracketsParseStrategy = .auto) {
      self.squareBrackets = squareBrackets
    }
  }

  let input: Input
  let utf8: Input.UTF8View

  public var configuration: Configuration?

  public var squareBrackets: Configuration.SquareBracketsParseStrategy {
    get {
      return configuration?.squareBrackets ?? .auto
    }
    set {
      var newConfig = self.configuration ?? .init()
      newConfig.squareBrackets = newValue
      self.configuration = newConfig
    }
  }

  public init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  public init(input: Input, squareBrackets: Configuration.SquareBracketsParseStrategy) {
    self.init(input: input, configuration: .init(squareBrackets: squareBrackets))
  }

  mutating func _parseContent(
    from startIndex: Input.UTF8View.Index
  ) -> (content: IPvFutureAddress, endIndex: Input.Index)? {
    var currentIndex = startIndex
    guard let _ = self.readCurrentCodeUnit(
      at: &currentIndex,
      ifAllowedCodeUnit: { $0 == 0x56 || $0 == 0x76 } // "V" or "v"
    ) else {
      return nil
    }
    guard let version = self.parseInt(from: &currentIndex, radix: 16) else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isPeriod) else {
      return nil
    }
    guard let stringRepresentation = self.parseString(
      from: &currentIndex,
      while: \._isAvailableInIPvFutureStringRepresentation
    ) else {
      return nil
    }
    return (
      IPvFutureAddress(version: version, _validatedStringRepresentation: stringRepresentation._string),
      currentIndex
    )
  }

  public mutating func parse() -> (output: IPvFutureAddress, endIndex: Input.Index)? {
    switch self.squareBrackets {
    case .required:
      return self._parseContentEnclosedBySquareBrackets() as (Output, Input.Index)?
    case .unacceptable:
      return self._parseContent(from: self.utf8.startIndex) as (Output, Input.Index)?
    case .auto:
      return (
        self._parseContentEnclosedBySquareBrackets() ??
        self._parseContent(from: self.utf8.startIndex)
      ) as (Output, Input.Index)?
    }
  }
}

internal struct _SomeIPAddressEnclosedBySquareBracketsParser<Input>: StringParser, _EnclosedBySquareBracketsParser
where Input: StringProtocol {
  enum Output {
    case ipv6Address(IPAddress)
    case ipvFutureAddress(IPvFutureAddress)
  }

  let input: Input
  let utf8: Input.UTF8View
  init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  func _parseContent(from startIndex: Input.UTF8View.Index) -> (content: Output, endIndex: Input.Index)? {
    var currentIndex = startIndex
    if let ipv6 = IPv6AddressParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: .init(squareBrackets: .unacceptable)
    ) {
      return (.ipv6Address(ipv6), currentIndex)
    } else if let ipvFuture = IPvFutureAddressParser<Input.SubSequence>.parse(
      input,
      from: &currentIndex,
      configuration: .init(squareBrackets: .unacceptable)
    ) {
      return (.ipvFutureAddress(ipvFuture), currentIndex)
    }
    return nil
  }

  mutating func parse() -> (output: Output, endIndex: Input.Index)? {
    return _parseContentEnclosedBySquareBrackets() as (Output, Input.Index)?
  }
}

extension IPAddress {
  /// Initialize with the array of `UInt8`.
  /// - parameter bytes: the array of `UInt8` representing IP Address.
  /// - returns: `.v4` address if the length of bytes is equal to 4,
  ///            `.v6` address if the length of bytes is equal to 6,
  ///            `nil` if otherwise.
  public init?(bytes:[UInt8]) {
    if bytes.count == 4 {
      self = .v4(bytes[0], bytes[1], bytes[2], bytes[3])
    } else if bytes.count == 16 {
      self = .v6(bytes[0], bytes[1], bytes[2], bytes[3],
                 bytes[4], bytes[5], bytes[6], bytes[7],
                 bytes[8], bytes[9], bytes[10], bytes[11],
                 bytes[12], bytes[13], bytes[14], bytes[15])
    } else {
      return nil
    }
  }
}

extension IPAddress: _InitializableWithParser {
  /// Initialize with the string.
  /// - parameter string: the string representing IP Address.
  /// - returns: `.v4` address if the string is valid for IPv4,
  ///            `.v6` address if the string is valid for IPv6,
  ///            `nil` if otherwise.
  public init?<S>(string: S) where S: StringProtocol {
    guard let ip = (
      IPAddress(string, parser: IPv4AddressParser.self) ??
      IPAddress(string, parser: IPv6AddressParser.self, configuration: .init(squareBrackets: .auto))
    ) else {
      return nil
    }
    self = ip
  }
}

extension IPvFutureAddress: _InitializableWithParser {
  public init?<S>(string: S) where S: StringProtocol {
    self.init(
      string,
      parser: IPvFutureAddressParser.self,
      configuration: .init(squareBrackets: .auto)
    )
  }
}

extension IPAddress {
  /// Calls the given closure with a pointer to the address in byte format.
  public func withUnsafeBufferPointer<Result>(_ body: (UnsafeBufferPointer<UInt8>) throws -> Result) rethrows -> Result {
    switch self {
    case .v4:
      return try self._cIPv4Address!.withUnsafeBufferPointer(body)
    case .v6:
      return try self._cIPv6Address!.withUnsafeBufferPointer(body)
    }
  }
}

/// Handles IPv4-Mapped Address
extension IPAddress {
  /// Check whether the instance is IPv4-mapped or not. Returns `false` if the instance is `.v4`.
  public var isIPv4Mapped: Bool {
    guard case .v6 = self else { return false }
    return self.withUnsafeBufferPointer {
      for ii in 0...9 {
        guard $0[ii] == 0 else { return false }
      }
      for ii in 10...11 {
        guard $0[ii] == 0xFF else { return false }
      }
      return true
    }
  }
  
  /// Returns IPv4Address, or `nil` if the instance is `.v6` and is not IPv4-mapped.
  public var v4Address: IPAddress? {
    if case .v4 = self { return self }
    guard self.isIPv4Mapped else { return nil }
    return self.withUnsafeBufferPointer { .v4($0[12], $0[13], $0[14], $0[15]) }
  }
}

extension IPAddress: Hashable {
  public static func ==(lhs:IPAddress, rhs:IPAddress) -> Bool {
    switch (lhs, rhs) {
    case (.v4, .v4), (.v6, .v6):
      return lhs.withUnsafeBufferPointer { (lp) -> Bool in
        return rhs.withUnsafeBufferPointer { (rp) -> Bool in
          assert(lp.count == rp.count)
          for ii in 0..<lp.count {
            if lp[ii] != rp[ii] { return false }
          }
          return true
        }
      }
    case (.v4, .v6):
      guard let mapped = rhs.v4Address else { return false }
      return lhs == mapped
    case (.v6, .v4):
      guard let mapped = lhs.v4Address else { return false }
      return mapped == rhs
    }
  }
  
  public func hash(into hasher:inout Hasher) {
    if case .v6 = self, let mapped = self.v4Address {
      mapped.hash(into: &hasher)
    } else {
      self.withUnsafeBufferPointer {
        for ii in 0..<$0.count {
          hasher.combine($0[ii])
        }
      }
    }
  }
}

/// Work with CIPAddress
extension IPAddress {
  private var _cIPv4Address: CIPv4Address? {
    guard case .v4(let b0, let b1, let b2, let b3) = self else { return nil }
    return CIPv4Address((b0, b1, b2, b3))
  }
  
  private var _cIPv6Address: CIPv6Address? {
    guard
      case .v6(let b0, let b1, let  b2, let  b3, let  b4, let  b5, let b6,
               let  b7, let b8, let b9, let b10, let b11, let b12, let b13, let b14, let b15) = self
      else {
      return nil
    }
    return CIPv6Address((b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15))
  }
  
  internal var _cIPv4SocketAddress: CIPv4SocketAddress? {
    return self._cIPv4Address.map({ CIPv4SocketAddress(ipAddress: $0) })
  }
  
  internal var _cIPv6SocketAddress: CIPv6SocketAddress? {
    return self._cIPv6Address.map({ CIPv6SocketAddress(ipAddress: $0) })
  }
}

extension IPAddress: CustomStringConvertible {
  public var description: String {
    return self._cIPv4Address?.description ?? self._cIPv6Address!.description
  }
}
