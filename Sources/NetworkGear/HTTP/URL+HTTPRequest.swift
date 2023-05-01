/* *************************************************************************************************
 URL+HTTPRequest.swift
   © 2019, 2022 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import yExtensions

extension URL {
  /// Represents HTTP Request.
  public struct Request {
    public enum Body {
      case data(Data)
      case stream(InputStream)
    }
    
    public var method: HTTPMethod
    public var header: HTTPHeader
    public var body: Body?
    public init(method: HTTPMethod = .get, header: HTTPHeader = [], body: Body? = nil) {
      self.method = method
      self.header = header
      self.body = body
    }
  }
}

private extension URLRequest {
  init(url: URL, request: URL.Request) {
    self.init(url: url)

    self.httpMethod = request.method.rawValue

    for field in request.header {
      self.addValue(field.value.rawValue, forHTTPHeaderField: field.name.rawValue)
    }

    switch request.body {
    case .some(.data(let data)):
      self.httpBody = data
    case .some(.stream(let stream)):
      self.httpBodyStream = stream
    default:
      break
    }
  }
}

extension URL {
  /// Represents HTTP Response
  public struct Response {
    public let statusCode: HTTPStatusCode
    public let header: HTTPHeader
    public let content: Data?
    
    fileprivate init(url: URL, response: HTTPURLResponse, data: Data?) {
      self.statusCode = HTTPStatusCode(rawValue: UInt16(response.statusCode))!
      
      let userInfo: [AnyHashable: Any] = ["url": url]
      var header: HTTPHeader = []
      for (maybeName, maybeValue) in response.allHeaderFields {
        if case let nameString as String = maybeName.base,
           case let valueString as String = maybeValue,
           let name = HTTPHeaderFieldName(rawValue: nameString),
           let value = HTTPHeaderFieldValue(rawValue: valueString)
        {
          header.insert(HTTPHeaderField(name: name, value: value, userInfo: userInfo))
        }
      }
      
      self.header = header
      self.content = data
    }
  }

  /// Returns an instance of `Response` representing the response to `request`.
  @available(macOS, deprecated: 12.0, renamed: "response(to:followRedirects:)")
  @available(iOS, deprecated: 15.0, renamed: "response(to:followRedirects:)")
  @available(watchOS, deprecated: 8.0, renamed: "response(to:followRedirects:)")
  @available(tvOS, deprecated: 15.0, renamed: "response(to:followRedirects:)")
  public func response(to request: Request) throws -> Response {
    enum _Result {
      case error(Error)
      case response(HTTPURLResponse, data: Data?)
    }
    var result: _Result = .error(NSError(domain: "Unexpected Error.", code: -1))

    let semaphore = DispatchSemaphore(value: 0)
    let handler: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
      if case let httpResponse as HTTPURLResponse = response {
        result = .response(httpResponse, data: data)
      } else if let someError = error {
        result = .error(someError)
      }
      semaphore.signal()
    }
    let task = URLSession.shared.dataTask(with: URLRequest(url: self, request: request), completionHandler: handler)
    task.resume()
    semaphore.wait()
    
    switch result {
    case .error(let error):
      throw error
    case .response(let httpResponse, data: let data):
      return .init(url: self, response: httpResponse, data: data)
    }
  }

  public enum ResponseError: Error {
    case notHTTPURLResponse
    case tooManyRedirects
    case missingLocationHeaderField(URL)
    case unexpectedLocation(String)
  }

  /// Returns an instance of `Response` representing the response to `request`.
  /// - parameter followRedirects:
  ///     Specify whether or not redirects should be followed.
  @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
  public func response(to request: Request, followRedirects: Bool) async throws -> Response {
    func __response(from url: URL, to request: Request) async throws -> Response {
      // URLSession missing async APIs: https://bugs.swift.org/browse/SR-15187
      #if canImport(Darwin)
      let (data, response) = try await URLSession.shared.data(for: URLRequest(url: self, request: request))
      guard case let httpResponse as HTTPURLResponse = response else {
        throw ResponseError.notHTTPURLResponse
      }
      return .init(url: url, response: httpResponse, data: data)
      #else
      return try url.response(to: request)
      #endif
    }
    if !followRedirects {
      return try await __response(from: self, to: request)
    }

    let cutOff = 20
    var nn = 0
    var currentURL = self
    while true {
      nn += 1
      if nn > cutOff {
        throw ResponseError.tooManyRedirects
      }

      let response = try await __response(from: currentURL, to: request)
      if !response.statusCode.requiresLocationHeader {
        return response
      }
      guard let location = response.header[.location].first else {
        throw ResponseError.missingLocationHeaderField(currentURL)
      }
      currentURL = try ({ () throws -> URL in
        if case let url as URL = location.source {
          return url
        }
        let string = location.value.rawValue
        if let url = URL(string: string) {
          return url
        }
        if let url = URL(string: string, relativeTo: currentURL) {
          return url
        }
        throw ResponseError.unexpectedLocation(string)
      })()
    }
  }

  @available(macOS, deprecated: 12.0, renamed: "finalContent")
  @available(iOS, deprecated: 15.0, renamed: "finalContent")
  @available(watchOS, deprecated: 8.0, renamed: "finalContent")
  @available(tvOS, deprecated: 15.0, renamed: "finalContent")
  @inlinable
  public var content: Data? {
    return (try? self.response(to: Request()))?.content
  }


  /// Returns the content at the URL. Request will follow all redirects.
  @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
  @inlinable
  public var finalContent: Data? {
    get async throws {
      if isFileURL {
        guard isExistingLocalFile else {
          throw POSIXError(.ENOENT)
        }
        let fh = try FileHandle(forReadingFrom: self)
        try fh.seek(toOffset: 0)
        return try fh.readToEnd()
      }
      return try await response(to: Request(), followRedirects: true).content
    }
  }
  
  @inlinable
  public var stream: InputStream? {
    return InputStream(url: self)
  }
}


private var _syncHeaderCache: [URL: HTTPHeader] = [:]
extension URL {
  @available(macOS, deprecated: 12.0)
  @available(iOS, deprecated: 15.0)
  @available(watchOS, deprecated: 8.0)
  @available(tvOS, deprecated: 15.0)
  private var __header: HTTPHeader? {
    if let header = _syncHeaderCache[self] {
      return header
    }
    guard let response = try? self.response(to: .init(method: .head)) else { return nil }
    _syncHeaderCache[self] = response.header
    return response.header
  }

  /// Returns the date when the resource at URL modified last.
  @available(macOS, deprecated: 12.0)
  @available(iOS, deprecated: 15.0)
  @available(watchOS, deprecated: 8.0)
  @available(tvOS, deprecated: 15.0)
  public var lastModified: Date? {
    return self.__header?[.lastModified].first?.source as? Date
  }

  /// Returns the ETag value of the URL.
  @available(macOS, deprecated: 12.0)
  @available(iOS, deprecated: 15.0)
  @available(watchOS, deprecated: 8.0)
  @available(tvOS, deprecated: 15.0)
  public var eTag: HTTPETag? {
    return self.__header?[.eTag].first?.source as? HTTPETag
  }
}

extension URL {
  @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
  private actor _HeaderCache {
    private var _cache: [URL: HTTPHeader] = [:]
    private init() {}

    static let shared: _HeaderCache = .init()

    func header(of url: URL) async throws -> HTTPHeader {
      guard let header = _cache[url] else {
        func __setCache(from response: URL.Response) {
          _cache[url] = _cache[url, default: response.header]
        }

        do {
          __setCache(from: try await url.response(to: .init(method: .head), followRedirects: true))
        } catch {
          // FIXME: Want to avoid using GET.
          // Under some circumstances (e.g. content is generated via CGI), the connection would be
          // lost when the method is HEAD.
          let nsError = error as NSError
          guard nsError.domain == NSURLErrorDomain && nsError.code == -1005 else {
            throw error
          }
          __setCache(from: try await url.response(to: .init(method: .get), followRedirects: true))
        }
        return _cache[url]!
      }
      return header
    }
  }

  @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
  private var _header: HTTPHeader {
    get async throws {
      return try await _HeaderCache.shared.header(of: self)
    }
  }

  /// Returns the date when the resource at URL modified last. Redirects are enabled.
  @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
  public var lastModifiedDate: Date? {
    get async throws {
      if isFileURL {
        return try FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date
      }
      return try await _header[.lastModified].first?.source as? Date
    }
  }

  /// Returns the ETag value of the URL, or `nil` if there is no ETag or the URL is a file URL.
  @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
  public var httpETag: HTTPETag? {
    get async throws {
      if isFileURL {
        return nil
      }
      return try await _header[.eTag].first?.source as? HTTPETag
    }
  }
}
