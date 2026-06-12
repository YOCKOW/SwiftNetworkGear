/* *************************************************************************************************
 CacheControlDirective.swift
   © 2017-2019,2023,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

/// A string representation of an argument of cache directive.
public enum CacheControlDirectiveStringArgument: Sendable, CustomStringConvertible, Equatable {
  case token(HTTPTokenString)
  case quotedString(QuotedString)

  public var description: String {
    return switch self {
    case .token(let token): token._string
    case .quotedString(let quotedString): quotedString.quotedString
    }
  }

  public static func ==(
    lhs: CacheControlDirectiveStringArgument,
    rhs: CacheControlDirectiveStringArgument
  ) -> Bool {
    switch (lhs, rhs) {
    case (.token(let lToken), .token(let rToken)): return lToken == rToken
    case (.quotedString(let lQS), .quotedString(let rQS)): return lQS.content == rQS.content
    default: return false
    }
  }
}

/// Reporesents directives of Cache-Control
///
/// ## References
///   - [RFC 9111](https://datatracker.ietf.org/doc/html/rfc9111#section-5.2)
///   - [Hypertext Transfer Protocol (HTTP) Cache Directive Registry by IANA](https://www.iana.org/assignments/http-cache-directives/http-cache-directives.xhtml)
///   - [Cache-Control - HTTP | MDN](https://developer.mozilla.org/en/docs/Web/HTTP/Headers/Cache-Control)
public enum CacheControlDirective: Sendable {
  // MARK: RFC 9111 - Request & Response Directives

  /// `max-age` directive.
  case maxAge(seconds: UInt)

  @available(*, deprecated, renamed: "maxAge(seconds:)")
  public static func maxAge(_ seconds: UInt) -> CacheControlDirective {
    return .maxAge(seconds: seconds)
  }

  /// `no-cache` directive.
  case noCache

  /// `no-store` directive.
  case noStore

  /// `no-transform` directive.
  case noTransform


  // MARK: RFC 9111 - Request Directives

  /// `max-stale` directive.
  case maxStale(seconds: UInt)

  @available(*, deprecated, renamed: "maxStale(seconds:)")
  public static func maxStale(_ seconds: UInt?) -> CacheControlDirective {
    return .maxAge(seconds: seconds ?? 0)
  }

  /// `min-fresh` directive.
  case minFresh(seconds: UInt)

  @available(*, deprecated, renamed: "minFresh(seconds:)")
  public static func minFresh(_ seconds: UInt) -> CacheControlDirective {
    return .minFresh(seconds: seconds)
  }

  /// `only-if-cached` directive.
  case onlyIfCached


  // MARK: RFC 9111 - Response Directives

  /// `must-revalidate` directive.
  case mustRevalidate

  /// `must-understand` directive.
  case mustUnderstand

  /// `private` directive.
  case `private`(fieldNames: [HTTPHeaderFieldName]?)

  /// `private` directive without any field names.
  public static let `private`: CacheControlDirective = .private(fieldNames: nil)

  /// `proxy-revalidate` directive.
  case proxyRevalidate

  /// `public` directive.
  case `public`

  /// `s-maxage` directive
  case sharedCacheMaxAge(seconds: UInt)

  @available(*, deprecated, renamed: "sharedCacheMaxAge(seconds:)")
  public static func sMaxAge(_ seconds:UInt) -> CacheControlDirective {
    return .sharedCacheMaxAge(seconds: seconds)
  }

  // MARK: RFC 5861 - HTTP Cache-Control Extensions for Stale Content

  /// `stale-while-revalidate` directive.
  case staleWhileRevalidate(seconds: UInt)

  @available(*, deprecated, renamed: "staleWhileRevalidate(seconds:)")
  public static func staleWhileRevalidate(_ seconds: UInt) -> CacheControlDirective {
    return .staleWhileRevalidate(seconds: seconds)
  }

  /// `stale-if-error` directive.
  case staleIfError(seconds: UInt)

  @available(*, deprecated, renamed: "staleIfError(seconds:)")
  public static func staleIfError(_ seconds: UInt) -> CacheControlDirective {
    return .staleIfError(seconds: seconds)
  }

  // MARK: RFC 8246 - HTTP Immutable Responses

  /// `immutable` directive
  case immutable


  // MARK: Extension Directive

  /// Represents an extension derective.
  case `extension`(name: HTTPTokenString, argument: CacheControlDirectiveStringArgument?)

  @available(*, deprecated, renamed: "extension(name:argument:)")
  public static func `extension`(name: String, value: String) -> CacheControlDirective {
    return .extension(
      name: HTTPTokenString(validating: name)!,
      argument: HTTPTokenString(validating: value).map({
        CacheControlDirectiveStringArgument.token($0)
      }) ?? value._quotedString.map({ QuotedString(quotedString: $0) }).map({
        CacheControlDirectiveStringArgument.quotedString($0)
      })
    )
  }
}

extension CacheControlDirective {
  /// A parser to parse a string as `cache-directive` defined in
  ///  [RFC 9111 §5.2](https://datatracker.ietf.org/doc/html/rfc9111#section-5.2)
  ///
  ///  - Note: This is usually for internal use.
  public struct Parser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
    public typealias Output = CacheControlDirective

    let input: Input
    let utf8: Input.UTF8View

    public init(input: Input) {
      self.input = input
      self.utf8 = input.utf8
    }

    public mutating func parse() -> (output: CacheControlDirective, endIndex: Input.Index)? {
      guard let (name, nameEndIndex) = HTTPTokenParser<Input>.parse(input) else {
        return nil
      }

      func __nameIs(_ string: String) -> Bool {
        return name.isASCIICaseInsensitivelyEqual(to: string)
      }

      func __parseArgument(allowQuotedString: Bool) -> (
        argument: CacheControlDirectiveStringArgument,
        endIndex: Input.Index
      )? {
        var currentIndex = nameEndIndex
        guard let _ = self.readCurrentCodeUnit(
          at: &currentIndex,
          ifAllowedCodeUnit: \._isEqualSign
        ) else {
          return nil
        }

        let argumentString = input[currentIndex...]
        PARSE_QUOTED_STRING: if allowQuotedString {
          guard let (quotedString, argumentEndIndex) = QuotedStringParser<Input.SubSequence>.parse(argumentString) else {
            break PARSE_QUOTED_STRING
          }
          return (argument: .quotedString(quotedString), endIndex: argumentEndIndex)
        }
        guard let (token, argumentEndIndex) = HTTPTokenParser<Input.SubSequence>.parse(argumentString) else {
          return nil
        }
        return (argument: .token(token), endIndex: argumentEndIndex)
      }

      func __parseArgumentUInt() -> (uint: UInt, endIndex: Input.Index)? {
        guard let argResult = __parseArgument(allowQuotedString: false),
              case .token(let token) = argResult.argument,
              let uint = UInt(token) else {
          return nil
        }
        return (uint: uint, endIndex: argResult.endIndex)
      }

      if __nameIs("max-age") {
        guard let (seconds, endIndex) = __parseArgumentUInt() else { return nil }
        return (.maxAge(seconds: seconds), endIndex)
      } else if __nameIs("no-cache") {
        return (.noCache, nameEndIndex)
      } else if __nameIs("no-store") {
        return (.noStore, nameEndIndex)
      } else if __nameIs("no-transform") {
        return (.noTransform, nameEndIndex)
      } else if __nameIs("max-stale") {
        guard let (seconds, endIndex) = __parseArgumentUInt() else { return nil }
        return (.maxStale(seconds: seconds), endIndex)
      } else if __nameIs("min-fresh") {
        guard let (seconds, endIndex) = __parseArgumentUInt() else { return nil }
        return (.minFresh(seconds: seconds), endIndex)
      } else if __nameIs("only-if-cached") {
        return (.onlyIfCached, nameEndIndex)
      } else if __nameIs("must-revalidate") {
        return (.mustRevalidate, nameEndIndex)
      } else if __nameIs("must-understand") {
        return (.mustUnderstand, nameEndIndex)
      } else if __nameIs("private") {
        guard let argResult = __parseArgument(allowQuotedString: true) else {
          return (.private, nameEndIndex)
        }
        // While we must accept only `quoted-string` acceding to RFC 9111,
        // here we accept also just a `token` for compatibility.
        let fieldNameListString: String = switch argResult.argument {
        case .token(let token): token.description
        case .quotedString(let quotedString): quotedString.content
        }
        guard let (list, _) = ListParser<String,HTTPHeaderFieldNameParser<Substring>>.parse(fieldNameListString) else {
          return (.private, argResult.endIndex)
        }
        return (.private(fieldNames: list), argResult.endIndex)
      } else if __nameIs("proxy-revalidate") {
        return (.proxyRevalidate, nameEndIndex)
      } else if __nameIs("public") {
        return (.public, nameEndIndex)
      } else if __nameIs("s-maxage") {
        guard let (seconds, endIndex) = __parseArgumentUInt() else { return nil }
        return (.sharedCacheMaxAge(seconds: seconds), endIndex)
      } else if __nameIs("stale-while-revalidate") {
        guard let (seconds, endIndex) = __parseArgumentUInt() else { return nil }
        return (.staleWhileRevalidate(seconds: seconds), endIndex)
      } else if __nameIs("stale-if-error") {
        guard let (seconds, endIndex) = __parseArgumentUInt() else { return nil }
        return (.staleIfError(seconds: seconds), endIndex)
      } else if __nameIs("immutable") {
        return (.immutable, nameEndIndex)
      } else {
        if let (arg, argEndIndex) = __parseArgument(allowQuotedString: true) {
          return (.extension(name: name, argument: arg), argEndIndex)
        } else {
          return (.extension(name: name, argument: nil), nameEndIndex)
        }
      }
    }
  }
}


extension CacheControlDirective: RawRepresentable, _InitializableWithParser {
  public init?(rawValue: String) {
    self.init(rawValue, parser: Parser<String>.self)
  }
  
  public var rawValue: String {
    switch self {
    case .maxAge(seconds: let seconds):
      return "max-age=\(String(seconds, radix: 10))"
    case .noCache:
      return "no-cache"
    case .noStore:
      return "no-store"
    case .noTransform:
      return "no-transform"
    case .maxStale(seconds: let seconds):
      return "max-stale=\(String(seconds, radix: 10))"
    case .minFresh(seconds: let seconds):
      return "min-fresh=\(String(seconds, radix: 10))"
    case .onlyIfCached:
      return "only-if-cached"
    case .mustRevalidate:
      return "must-revalidate"
    case .mustUnderstand:
      return "must-understand"
    case .private(fieldNames: let optionalFieldNames):
      if let filedNames = optionalFieldNames,
         let fieldNamesString = filedNames.map({ $0.rawValue }).joined(separator: ",")._quotedString {
        return "private=\(fieldNamesString)"
      }
      return "private"
    case .proxyRevalidate:
      return "proxy-revalidate"
    case .public:
      return "public"
    case .sharedCacheMaxAge(seconds: let seconds):
      return "s-maxage=\(String(seconds, radix: 10))"
    case .staleWhileRevalidate(seconds: let seconds):
      return "stale-while-revalidate=\(String(seconds, radix: 10))"
    case .staleIfError(seconds: let seconds):
      return "stale-if-error=\(String(seconds, radix: 10))"
    case .immutable:
      return "immutable"
    case .extension(name: let name, argument: let optionalArg):
      if let argument = optionalArg {
        return "\(name._string)=\(argument.description)"
      }
      return name._string
    }
  }
}

extension CacheControlDirective: Hashable {
  public static func ==(lhs:CacheControlDirective, rhs:CacheControlDirective) -> Bool {
    switch (lhs, rhs) {
    case (.maxAge(let lsec), .maxAge(let rsec)):
      return lsec == rsec
    case (.noCache, .noCache), (.noStore, .noStore), (.noTransform, .noTransform):
      return true
    case (.maxStale(let lsec), .maxStale(let rsec)):
      return lsec == rsec
    case (.minFresh(let lsec), .minFresh(let rsec)):
      return lsec == rsec
    case (.onlyIfCached, .onlyIfCached): return true
    case (.mustRevalidate, .mustRevalidate), (.mustUnderstand, .mustUnderstand):
      return true
    case (.private(let lList), .private(let rList)):
      return lList == rList
    case (.proxyRevalidate, .proxyRevalidate), (.public, .public):
      return true
    case (.sharedCacheMaxAge(let lsec), .sharedCacheMaxAge(let rsec)):
      return lsec == rsec
    case (.staleWhileRevalidate(let lsec), .staleWhileRevalidate(let rsec)):
      return lsec == rsec
    case (.staleIfError(let lsec), .staleIfError(let rsec)):
      return lsec == rsec
    case (.immutable, .immutable):
      return true
    case (.extension(let lName, let lArg), .extension(let rName, let rArg)):
      return lName == rName && lArg == rArg
    default:
      return false
    }
  }
  
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self.rawValue)
  }
}

infix operator =~
infix operator !~
extension CacheControlDirective {
  internal static func =~(lhs:CacheControlDirective, rhs:CacheControlDirective) -> Bool {
    switch (lhs, rhs) {
    case (.maxAge, .maxAge),
         (.noCache, .noCache),
         (.noStore, .noStore),
         (.noTransform, .noTransform),
         (.maxStale, .maxStale),
         (.minFresh, .minFresh),
         (.onlyIfCached, .onlyIfCached),
         (.mustRevalidate, .mustRevalidate),
         (.mustUnderstand, .mustUnderstand),
         (.private, .private),
         (.proxyRevalidate, .proxyRevalidate),
         (.public, .public),
         (.sharedCacheMaxAge, .sharedCacheMaxAge),
         (.staleWhileRevalidate, .staleWhileRevalidate),
         (.staleIfError, .staleIfError),
         (.immutable, .immutable):
      return true
    case (.extension(let lName, _), .extension(let rName, _)):
      return lName == rName
    default: return false
    }
  }
  
  internal static func !~(lhs:CacheControlDirective, rhs:CacheControlDirective) -> Bool {
    return (lhs =~ rhs) ? false : true
  }
}

