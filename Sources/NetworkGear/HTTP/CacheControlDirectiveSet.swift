/* *************************************************************************************************
 CacheControlDirectiveSet.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
/// A set for `CacheControlDirective`
public struct CacheControlDirectiveSet: Sendable {
  fileprivate enum _Key: Hashable, Sendable {
    case maxAge
    case noCache
    case noStore
    case noTransform
    case maxStale
    case minFresh
    case onlyIfCached
    case mustRevalidate
    case mustUnderstand
    case `private`
    case proxyRevalidate
    case `public`
    case sharedCacheMaxAge
    case staleWhileRevalidate
    case staleIfError
    case immutable
    case `extension`(name: ASCIICaseInsensitiveString)

    fileprivate init(_ directive: CacheControlDirective) {
      switch directive {
      case .maxAge: self = .maxAge
      case .noCache: self = .noCache
      case .noStore: self = .noStore
      case .noTransform: self = .noTransform
      case .maxStale: self = .maxStale
      case .minFresh: self = .minFresh
      case .onlyIfCached: self = .onlyIfCached
      case .mustRevalidate: self = .mustRevalidate
      case .mustUnderstand: self = .mustUnderstand
      case .private: self = .private
      case .proxyRevalidate: self = .proxyRevalidate
      case .public: self = .public
      case .sharedCacheMaxAge: self = .sharedCacheMaxAge
      case .staleWhileRevalidate: self = .sharedCacheMaxAge
      case .staleIfError: self = .staleIfError
      case .immutable: self = .immutable
      case .extension(let name, _): self = .extension(name: ASCIICaseInsensitiveString(name))
      }
    }
  }
  
  private var _store: [_Key:CacheControlDirective] = [:]
  
  /// Returns a Boolean value that indicates whether the given directive exists in the set.
  public func contains(_ directive:CacheControlDirective) -> Bool {
    return self._store[_Key(directive)] == directive
  }
  
  /// Returns a Boolean value that indicates whether the same-case directive  exists in the set.
  public func contains(sameCaseWith directive:CacheControlDirective) -> Bool {
    return self._store[_Key(directive)] != nil
  }
  
  @discardableResult
  public mutating func insert(_ directive:CacheControlDirective) -> CacheControlDirective {
    let key = _Key(directive)
    defer { self._store[key] = directive }
    
    if let oldDirective = self._store[_Key(directive)] {
      return oldDirective
    } else {
      return directive
    }
  }
  
  /// Initialize the set with `directives`
  public init(_ directives:CacheControlDirective...) {
    self._store = [:]
    for directive in directives {
      self.insert(directive)
    }
  }
}

extension CacheControlDirectiveSet: Hashable {}

extension CacheControlDirectiveSet: HTTPHeaderFieldValueConvertible {
  public init?(_ value: HTTPHeaderFieldValue) {
    var parser = ListParser<String, CacheControlDirective.Parser<Substring>>(input: value.rawValue)
    guard let (directives, _) = parser.parse() else {
      return nil
    }

    self.init()
    for directive in directives {
      self.insert(directive)
    }
  }
  
  public var httpHeaderFieldValue: HTTPHeaderFieldValue {
    return HTTPHeaderFieldValue(rawValue:self._store.values.map{ $0.rawValue }.joined(separator:", "))!
  }
}

extension CacheControlDirectiveSet {
  internal var _directives: [CacheControlDirective] {
    return Array(self._store.values)
  }
}

extension CacheControlDirectiveSet: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = CacheControlDirective
  public init(arrayLiteral elements: CacheControlDirective...) {
    self._store = [:]
    for directive in elements {
      self.insert(directive)
    }
  }
}
