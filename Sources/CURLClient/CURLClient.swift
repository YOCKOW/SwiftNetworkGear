/* *************************************************************************************************
 CURLClient.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CLibCURL
import Dispatch
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import  Foundation

public enum CURLClientError: Error, Equatable {
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

  nonisolated(unsafe) private static var _shared: CURLManager? = nil
  private static let _sharedQueue: DispatchQueue = .init(
    label: "jp.YOCKOW.CURLClient.sharedQueue",
    attributes: .concurrent
  )

  public static var shared: CURLManager {
    return _sharedQueue.sync(flags: .barrier) {
      guard let singleton = _shared else {
        _shared = CURLManager()
        atexit {
          CURLManager._shared?.clean()
          CURLManager._shared = nil
        }
        return _shared!
      }
      return singleton
    }
  }
}

/// A wrapper of a CURL easy handle.
public actor EasyClient {
  public static let defaultUserAgent: String = ({
    let libcurlVersion = String(cString: CURLManager.shared._libcurlVersion.pointee.version)
    return "SwiftNetworkGearClient/0.1 (libcurl/\(libcurlVersion)) https://GitHub.com/YOCKOW/SwiftNetworkGear"
  })()

  nonisolated(unsafe) private let _curlHandle: UnsafeMutableRawPointer

  private var _cleaned: Bool = false

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
    if !_cleaned {
      curl_easy_cleanup(_curlHandle)
      _cleaned = true
    }
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

  private func __setRequestHeaderHandler(
    _ userInfoPointer: UnsafeMutablePointer<_UserInfo>
  ) throws {
    let list = try userInfoPointer.pointee.requestHeaderFieldList
    try _throwIfFailed({ _NWG_curl_easy_set_http_request_headers($0, list) })
  }

  private func __setRequestBodyHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
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

  private func __setRequestBodyRewinder(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
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

  private func __setResponseCodeHeaderHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
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

  private func __setResponseBodyHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
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

  private func __performImpl(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
    // `Apache + HTTP/2 + CGI + HEAD` may cause stream error in the HTTP/2 framing layer.
    func __ignoreHTTP2HeadError(_ error: any Error, userInfo: _UserInfo) throws -> Bool {
      guard case CURLClientError.curlCode(let curlCode) = error,
            curlCode == CURLE_HTTP2_STREAM else {
        return false
      }
      guard let statusLine = userInfo._statusLine,
            statusLine.httpVersion.major == 2 else {
        return false
      }
      var methodStringPointer: UnsafeMutablePointer<CChar>? = nil
      try withUnsafeMutablePointer(to: &methodStringPointer) { (methodStringPointerPointer) in
        try _throwIfFailed {
          _NWG_curl_easy_get_effective_method($0, methodStringPointerPointer)
        }
      }
      guard let methodStringPointer else {
        return false
      }
      let isHEAD = String(cString: methodStringPointer, encoding: .utf8) == "HEAD"
      if isHEAD {
        userInfo.finalizeResponseHeader()
      }
      return isHEAD
    }

    do {
      try _throwIfFailed({ _NWG_curl_easy_perform($0) })
    } catch {
      // Ad-hoc error handling...
      var unignorableError: (any Error)? = error

      if try __ignoreHTTP2HeadError(error, userInfo: userInfoPointer.pointee) {
        unignorableError = nil
      }

      if let unignorableError {
        throw unignorableError
      }
    }
  }

  /// Call `curl_easy_perform` with the handle.
  public func perform<Delegate>(delegate: Delegate) async throws where Delegate: CURLClientDelegate {
    if _performed {
      return
    }
    defer { _performed = true }

    try await delegate.willStartPerforming(client: self)

    // Avoid "⛔️the compiler is unable to type-check this expression in reasonable time" 😓

    var delegate = delegate
    try withUnsafeMutablePointer(to: &delegate) { delegatePointer in
      var userInfo = try _UserInfo(
        delegatePointer: delegatePointer,
        requestBodySize: _requestBodySize,
        maxNumberOfRedirectsAllowed: _maxNumberOfRedirectsAllowed
      )
      try withUnsafeMutablePointer(to: &userInfo) { userInfoPointer in
        // Note: Somehow `defer` can't be used here in Swift 6.0.1 on macOS😭
        // https://github.com/YOCKOW/SwiftNetworkGear/issues/57
        try __setRequestHeaderHandler(userInfoPointer)
        try __setRequestBodyHandler(userInfoPointer)
        try __setRequestBodyRewinder(userInfoPointer)
        try __setResponseCodeHeaderHandler(userInfoPointer)
        try __setResponseBodyHandler(userInfoPointer)
        try __performImpl(userInfoPointer)
      }
    }

    try await delegate.didFinishPerforming(client: self)
  }

  // MARK: /PERFORM -
}

extension CURLManager {
  public func makeEasyClient() throws -> EasyClient {
    return try EasyClient()
  }
}
