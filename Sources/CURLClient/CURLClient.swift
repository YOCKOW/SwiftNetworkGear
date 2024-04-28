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

public enum CURLClientError: Error, Equatable {
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

  fileprivate private(set) lazy var _libcurlVersion = _NWG_curl_version_info_now()

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
  public static let defaultUserAgent: String = ({
    let libcurlVersion = String(cString: CURLManager.shared._libcurlVersion.pointee.version)
    return "SwiftNetworkGearClient/0.1 (libcurl/\(libcurlVersion)) https://GitHub.com/YOCKOW/SwiftNetworkGear"
  })()

  private let _curlHandle: UnsafeMutableRawPointer

  fileprivate init() throws {
    guard let curlHandle = curl_easy_init() else {
      throw CURLClientError.failedToCreateClient
    }
    _NWG_curl_easy_set_ua(
      curlHandle,
      EasyClient.defaultUserAgent
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

  public func setHTTPMethodToCustom(_ method: String) throws {
    try method.withCString { (cString) -> Void in
      try _throwIfFailed {
        _NWG_curl_easy_set_http_method_to_custom($0, UnsafeMutablePointer(mutating: cString))
      }
    }
  }

  public func setHTTPMethodToGet() throws {
    try _throwIfFailed({ _NWG_curl_easy_set_http_method_to_get($0) })
  }

  public func setHTTPMethodToHead() throws {
    try _throwIfFailed({ _NWG_curl_easy_set_http_method_to_head($0) })
  }

  public func setHTTPMethodToPost() throws {
    try _throwIfFailed({ _NWG_curl_easy_set_http_method_to_post($0) })
  }

  public func setHTTPMethodToPut() throws {
    try _throwIfFailed({ _NWG_curl_easy_set_http_method_to_put($0) })
  }

  private var _maxNumberOfRedirectsAllowed: Int = 0

  /// - parameters:
  ///   - amount:
  ///     * Negative number: Accept an infinite number of redirects.
  ///     * `0`: Refuse any redirect.
  ///     * Positive number: The redirection limit amount.
  public func setMaxNumberOfRedirectsAllowed(_ amount: Int) throws {
    func __set(enable: Bool, maxCount: Int) throws {
      _maxNumberOfRedirectsAllowed = maxCount
      try _throwIfFailed({ _NWG_curl_easy_set_follow_location($0, enable) })
      try _throwIfFailed({ _NWG_curl_easy_set_max_redirects($0, maxCount) })
    }

    switch amount {
    case ..<0:
      try __set(enable: true, maxCount: -1)
    case 0:
      try __set(enable: false, maxCount: 0)
    default:
      try __set(enable: true, maxCount: amount)
    }
  }

  private var _requestBodySize: Int? = nil

  public func setUploadFileSize(_ size: CCURLOffset) throws {
    _requestBodySize = Int(size)
    try _throwIfFailed({ _NWG_curl_easy_set_upload_file_size($0, size) })
  }

  public func setURL(_ url: URL) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_url($0, url.absoluteString) })
  }

  public func setUserAgent(_ userAgent: String) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_ua($0, userAgent) })
  }

  // MARK: - PERFORM

  private var _performed: Bool = false

  /// Call `curl_easy_perform` with the handle.
  public func perform<Delegate>(delegate: inout Delegate) throws where Delegate: CURLClientDelegate {
    if _performed {
      return
    }
    defer { _performed = true }

    // Avoid "⛔️the compiler is unable to type-check this expression in reasonable time" 😓

    func __setRequestHeaderHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws -> UnsafeMutablePointer<CCURLStringList>? {
      guard let requestHeaderFields = userInfoPointer.pointee.requestHeaderFields else {
        return nil
      }
      guard let firstField = requestHeaderFields.first else {
        return nil
      }
      guard var currentList = _NWG_curl_slist_create("\(firstField.name): \(firstField.value)") else {
        throw CURLClientError.failedToGenerateRequestHeaders
      }
      for field in requestHeaderFields.dropFirst() {
        guard let newList = _NWG_curl_slist_append(currentList, "\(field.name): \(field.value)") else {
          _NWG_curl_slist_free_all(currentList)
          throw CURLClientError.failedToGenerateRequestHeaders
        }
        currentList = newList
      }
      try _throwIfFailed({ _NWG_curl_easy_set_http_request_headers($0, currentList) })
      return currentList
    }

    func __setRequestBodyHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
      guard userInfoPointer.pointee.hasRequestBody else { return }
      try _throwIfFailed {
        _NWG_curl_easy_set_read_user_info($0, UnsafeMutableRawPointer(userInfoPointer))
      }
      try _throwIfFailed {
        _NWG_curl_easy_set_read_function($0) { (buffer,
                                                _,
                                                maxLength,
                                                maybePointer) -> CSize in
          return maybePointer?.assumingMemoryBound(
            to: _UserInfo.self
          ).pointee.readNextPartialRequestBody(
            buffer,
            maxLength: maxLength
          ) ?? -1
        }
      }
    }

    func __setRequestBodyRewinder(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
      try _throwIfFailed { _NWG_curl_easy_set_seek_user_info($0, userInfoPointer) }
      try _throwIfFailed {
        _NWG_curl_easy_set_seek_function($0) { (maybePointer, offset, origin) -> CInt in
          guard let userInfoPointer = maybePointer?.assumingMemoryBound(to: _UserInfo.self) else {
            return CInt(NWGCURLSeekFail.rawValue)
          }
          do {
            let result = try userInfoPointer.pointee.rewindRequestBody(
              toOffset: UInt64(offset),
              from: NWGCURLSeekOrigin(UInt32(origin))
            )
            return result ? CInt(NWGCURLSeekOK.rawValue) : CInt(NWGCURLSeekUndone.rawValue)
          } catch {
            return CInt(NWGCURLSeekFail.rawValue)
          }
        }
      }
    }

    func __setResponseCodeHeaderHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
      try _throwIfFailed {
        _NWG_curl_easy_set_header_user_info($0, UnsafeMutableRawPointer(userInfoPointer))
      }
      try _throwIfFailed {
        _NWG_curl_easy_set_header_callback($0) { (line, _, length, maybePointer) -> CSize in
          guard let userInfoPointer = maybePointer?.assumingMemoryBound(to: _UserInfo.self) else {
            return -1
          }
          do {
            guard try userInfoPointer.pointee.handleResponseHeaderLine(line, length: length) else {
              return -1
            }
            return length
          } catch {
            return -1
          }
        }
      }
    }

    func __setResponseBodyHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
      try _throwIfFailed {
        _NWG_curl_easy_set_write_user_info(
          $0,
          UnsafeMutableRawPointer(userInfoPointer)
        )
      }
      try _throwIfFailed {
        _NWG_curl_easy_set_write_function($0) { (chunk, _, length, maybePointer) -> CSize in
          guard let userInfoPointer = maybePointer?.assumingMemoryBound(to: _UserInfo.self) else {
            return -1
          }
          return userInfoPointer.pointee.writeNextPartialResponseBody(chunk, length: length)
        }
      }
    }

    func __withUserInfoPointer<T>(_ job: (UnsafeMutablePointer<_UserInfo>) throws -> T) rethrows -> T {
      return try withUnsafeBytes(of: &delegate, {
        guard let delegatePointer = UnsafeMutablePointer<Delegate>(
          mutating: $0.assumingMemoryBound(to: Delegate.self).baseAddress
        ) else {
          fatalError("Unexpected pointer?!")
        }

        var userInfo = try _UserInfo(
          delegatePointer: delegatePointer,
          requestBodySize: _requestBodySize,
          maxNumberOfRedirectsAllowed: _maxNumberOfRedirectsAllowed
        )
        return try withUnsafeBytes(of: &userInfo, {
          guard let userInfoPointer = UnsafeMutablePointer<_UserInfo>(
            mutating: $0.assumingMemoryBound(to: _UserInfo.self).baseAddress
          ) else {
            fatalError("Unexpected pointer?!")
          }
          return try job(userInfoPointer)
        })
      })
    }

    try __withUserInfoPointer { (userInfoPointer) -> Void in
      // Request Header
      let requestHeaderFieldCURLList = try __setRequestHeaderHandler(userInfoPointer)
      defer {
        _NWG_curl_slist_free_all(requestHeaderFieldCURLList)
      }

      // Request Body
      try __setRequestBodyHandler(userInfoPointer)
      try __setRequestBodyRewinder(userInfoPointer)

      // Response Code & Header
      try __setResponseCodeHeaderHandler(userInfoPointer)

      // Response Body
      try __setResponseBodyHandler(userInfoPointer)

      // PERFORM!
      try _throwIfFailed({ _NWG_curl_easy_perform($0) })
    }
  }

  // MARK: /PERFORM -
}

extension CURLManager {
  public func makeEasyClient() throws -> EasyClient {
    return try EasyClient()
  }
}
