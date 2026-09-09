/* *************************************************************************************************
 HTTPBin.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import Testing

public enum HTTPBinServer: Sendable {
  case httpbin
  case httpcan
  case other(scheme: String, host: String, port: UInt16)

  public static var `default`: HTTPBinServer {
    let env = ProcessInfo.processInfo.environment
    guard let scheme = env["HTTPBIN_SCHEME"],
          let host = env["HTTPBIN_HOST"],
          let port = env["HTTPBIN_PORT"].flatMap({ UInt16($0) }) else {
      return .httpcan
    }
    return .other(scheme: scheme, host: host, port: port)
  }

  public var urlComponents: URLComponents {
    var components = URLComponents()
    switch self {
    case .httpbin:
      components.scheme = "https"
      components.host = "httpbin.org"
    case .httpcan:
      components.scheme = "https"
      components.host = "httpcan.org"
    case .other(let scheme, let host, let port):
      components.scheme = scheme
      components.host = host
      components.port = Int(port)
    }
    return components
  }

  public func url(
    withPath path: String,
    queryItems: [URLQueryItem]? = nil
  ) throws -> URL {
    var components = self.urlComponents
    components.path = path
    components.queryItems = queryItems
    return try #require(components.url)
  }

  public func url(
    withPath path: String,
    queries: [String: String?]
  ) throws -> URL {
    var queryItems: [URLQueryItem] = []
    for (key, value) in queries {
      queryItems.append(URLQueryItem(name: key, value: value))
    }
    return try self.url(withPath: path, queryItems: queryItems)
  }
}


