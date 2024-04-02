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
  case curlCode(CURLcode)

  public var description: String {
    switch self {
    case .failedToCreateClient:
      return "Failed to create a client."
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

    var responseBody = Data()
    try withUnsafeBytes(of: &responseBody) { (responseBodyPointer) -> Void in
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

    let responseCodePointer = UnsafeMutablePointer<CLong>.allocate(capacity: 1)
    defer { responseCodePointer.deallocate() }
    try _throwIfFailed({ _NWG_curl_easy_get_response_code($0, responseCodePointer) })

    var responseHeaders: Array<(name: String, value: String)> = []
    var previousHeaderInfo: UnsafeMutablePointer<CCURLHeader>? = nil
    while let headerInfo = _NWG_curl_easy_get_next_header(
      _curlHandle,
      UInt32(CURLH_HEADER | CURLH_1XX | CURLH_CONNECT | CURLH_TRAILER),
      0,
      previousHeaderInfo
    ) {
      responseHeaders.append((
        name: String(cString: headerInfo.pointee.name),
        value: String(cString: headerInfo.pointee.value)
      ))
      previousHeaderInfo = headerInfo
    }

    _responseCode = Int(responseCodePointer.pointee)
    _responseHeaders = responseHeaders
    _responseBody = responseBody
    _performed = true
  }

  // MARK: /PERFORM -

  public func setHTTPMethodToGet() throws {
    try _throwIfFailed({ _NWG_curl_easy_set_http_method_to_get($0) })
  }

  public func setURL(_ url: URL) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_url($0, url.absoluteString) })
  }

  public func setUserAgent(_ userAgent: String) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_ua($0, userAgent) })
  }
}

extension CURLManager {
  public func makeEasyClient() throws -> EasyClient {
    return try EasyClient()
  }
}
