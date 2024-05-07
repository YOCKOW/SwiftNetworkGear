/* *************************************************************************************************
 URL+HTTPResponseHeader.swift
   © 2019,2022,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

extension URL {
  private actor _HeaderCache {
    private var _cache: [URL: HTTPHeader] = [:]
    private init() {}

    static let shared: _HeaderCache = .init()

    func clearCache(for url: URL) {
      _cache[url] = nil
    }

    func header(of url: URL) async throws -> HTTPHeader {
      guard let header = _cache[url] else {
        let connection = SimpleHTTPConnection(url: url, method: .head)
        let response = try await connection.response()
        _cache[url] = response.header
        return _cache[url]!
      }
      return header
    }
  }

  /// Returns the response header.
  /// Throw an error if the scheme is not HTTP(S).
  ///
  /// - Parameters:
  ///   * useCache: Use internal cache if its value is `true`.
  public func responseHeader(useCache: Bool = true) async throws -> HTTPHeader {
    let cache = _HeaderCache.shared
    if !useCache {
      await cache.clearCache(for: self)
    }
    return try await cache.header(of: self)
  }

  /// Returns the date when the resource at URL modified last. Redirects are enabled.
  public var lastModifiedDate: Date? {
    get async throws {
      if isFileURL {
        return try FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date
      }
      return try await responseHeader()[.lastModified].first?.source as? Date
    }
  }

  /// Returns the ETag value of the URL, or `nil` if there is no ETag or the URL is a file URL.
  public var httpETag: HTTPETag? {
    get async throws {
      if isFileURL {
        return nil
      }
      return try await responseHeader()[.eTag].first?.source as? HTTPETag
    }
  }
}
