/* *************************************************************************************************
 CURLClient.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CLibCURL
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import  Foundation

public enum CURLClientError: Error {
  case failedToCreateClient
  case failedToGenerateRequestHeaders
  case curlCode(CURLcode)

  public var description: String {
    switch self {
    case .failedToCreateClient:
      return "Failed to create a client."
    case .failedToGenerateRequestHeaders:
      return "Failed to generate request headers."
    case .curlCode(let code):
      return String(cString: curl_easy_strerror(code))
    }
  }
}

public final class CURLManager {
  init() {
    curl_global_init(.init(CURL_GLOBAL_ALL))
  }

  private var _cleaned: Bool = false

  private func clean() {
    if !_cleaned {
      curl_global_cleanup()
      _cleaned = true
    }
  }

  deinit {
    clean()
  }

  private static var _shared: CURLManager? = nil

  public static let shared: CURLManager = ({ () -> CURLManager in
    guard let singleton = _shared else {
      _shared = CURLManager()
      atexit {
        _shared?.clean()
        _shared = nil
      }
      return _shared!
    }
    return singleton
  })()
}

/// A wrapper of a CURL easy handle.
public actor EasyClient {
  private let _curlHandle: UnsafeMutableRawPointer

  init() throws {
    guard let curlHandle = curl_easy_init() else {
      throw CURLClientError.failedToCreateClient
    }
    _NWG_curl_easy_set_ua(
      curlHandle,
      "SwiftNetworkGearClient/0.1 https://GitHub.com/YOCKOW/SwiftNetworkGear"
    )
    self._curlHandle = curlHandle
  }

  deinit {
    curl_easy_cleanup(_curlHandle)
  }

  private func _throwIfFailed(_ job: (UnsafeMutableRawPointer) -> CURLcode) throws {
    let result = job(_curlHandle)
    if result != CURLE_OK {
      throw CURLClientError.curlCode(result)
    }
  }

  public func setHTTPMethodToGet() throws {
    try _throwIfFailed({ _NWG_curl_easy_set_http_method_to_get($0) })
  }

  private var _requestHeaders: Array<(name: String, value: String)>? = nil
  public func setRequestHeaders(_ headers: Array<(name: String, value: String)>) {
    _requestHeaders = headers
  }

  public func setURL(_ url: URL) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_url($0, url.absoluteString) })
  }

  public func setUserAgent(_ userAgent: String) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_ua($0, userAgent) })
  }

  // MARK: - PERFORM

  private var _performed: Bool = false
  private var _responseCode: Int? = nil
  private var _responseHeaders: Array<(name: String, value: String)>? = nil
  private var _responseBody: Data? = nil

  public var responseCode: Int? {
    return _responseCode
  }

  public var responseHeaders: Array<(name: String, value: String)>? {
    return _responseHeaders
  }

  public var responseBody: Data? {
    return _responseBody
  }

  /// Call `curl_easy_perform` with the handle.
  ///
  /// `responseBody` will be set in this method.
  public func perform() throws {
    if _performed {
      return
    }

    let requestHeaderList: UnsafeMutablePointer<CCURLStringList>? = try _requestHeaders.flatMap {
      guard let firstField = $0.first else { return nil }
      guard var currentList = _NWG_curl_slist_create("\(firstField.name): \(firstField.value)") else {
        throw CURLClientError.failedToGenerateRequestHeaders
      }
      for field in $0.dropFirst() {
        guard let newList = _NWG_curl_slist_append(currentList, "\(field.name): \(field.value)") else {
          _NWG_curl_slist_free_all(currentList)
          throw CURLClientError.failedToGenerateRequestHeaders
        }
        currentList = newList
      }
      return currentList
    }
    if let requestHeaderList {
      try _throwIfFailed({ _NWG_curl_easy_set_http_request_headers($0, requestHeaderList) })
    }
    defer { _NWG_curl_slist_free_all(requestHeaderList) }

    var responseHeaders: Array<(name: String, value: String)> = []
    var responseBody = Data()
    try withUnsafeBytes(of: &responseHeaders) { (responseHeadersPointer) -> Void in
      try withUnsafeBytes(of: &responseBody) { (responseBodyPointer) -> Void in
        // Headers
        try _throwIfFailed {
          _NWG_curl_easy_set_header_user_info(
            $0,
            UnsafeMutableRawPointer(mutating: responseHeadersPointer.baseAddress!)
          )
        }
        try _throwIfFailed {
          _NWG_curl_easy_set_header_callback($0) { (line, _, length, maybeResponseHeadersPointer) -> size_t in
            guard let responseHeadersPointer = maybeResponseHeadersPointer else { return -1 }
            guard let lineString = String(
              data: Data(bytesNoCopy: line, count: length, deallocator: .none),
              encoding: .utf8
            ) else {
              return -1
            }

            // Skip if necessary.
            if lineString.isEmpty || lineString.uppercased().hasPrefix("HTTP/") {
              return length
            }

            let responseHeadersTypedPointer = responseHeadersPointer.assumingMemoryBound(
              to: Array<(name: String, value: String)>.self
            )
            var responseHeaders = responseHeadersTypedPointer.pointee
            defer { responseHeadersTypedPointer.pointee = responseHeaders }

            // Folded header (actually deprecated...)
            if lineString.first!.isWhitespace {
              guard let lastField = responseHeaders.last else { return -1 }
              responseHeaders = responseHeaders.dropLast()
              responseHeaders.append((
                name: lastField.name,
                value: "\(lastField.value) \(lineString._trimmedHeaderLine)"
              ))
              return length
            }

            let nameAndValue = lineString.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard nameAndValue.count == 2 else { return -1 }
            responseHeaders.append((
              name: String(nameAndValue[0]._trimmedHeaderLine),
              value: String(nameAndValue[1]._trimmedHeaderLine)
            ))
            return length
          }
        }

        // Body
        try _throwIfFailed {
          _NWG_curl_easy_set_write_user_info(
            $0,
            UnsafeMutableRawPointer(mutating: responseBodyPointer.baseAddress!)
          )
        }
        try _throwIfFailed {
          _NWG_curl_easy_set_write_function($0) { (chunk, _, length, maybeResponseBodyPointer) -> size_t in
            guard let responseBodyPointer = maybeResponseBodyPointer else { return -1 }
            let chunkAsData = Data(bytesNoCopy: chunk, count: length, deallocator: .none)
            responseBodyPointer.assumingMemoryBound(to: Data.self).pointee.append(chunkAsData)
            return chunkAsData.count
          }
        }
        try _throwIfFailed({ _NWG_curl_easy_perform($0) })
      }
    }

    let responseCodePointer = UnsafeMutablePointer<CLong>.allocate(capacity: 1)
    defer { responseCodePointer.deallocate() }
    try _throwIfFailed({ _NWG_curl_easy_get_response_code($0, responseCodePointer) })

    _responseCode = Int(responseCodePointer.pointee)
    _responseHeaders = responseHeaders
    _responseBody = responseBody
    _performed = true
  }

  // MARK: /PERFORM -
}

extension CURLManager {
  public func makeEasyClient() throws -> EasyClient {
    return try EasyClient()
  }
}


private extension Character {
  var _isNewlineOrWhitespace: Bool {
    return isNewline || isWhitespace
  }
}

private extension StringProtocol {
  var _trimmedHeaderLine: SubSequence {
    guard let firstIndex = self.firstIndex(where: { !$0._isNewlineOrWhitespace }) else { return "" }
    guard let lastIndex = self.lastIndex(where: { !$0._isNewlineOrWhitespace }) else { return "" }
    return self[firstIndex...lastIndex]
  }
}
