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

  fileprivate init() throws {
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

  public func setUploadFileSize(_ size: CCURLOffset) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_upload_file_size($0, size) })
  }

  public func setURL(_ url: URL) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_url($0, url.absoluteString) })
  }

  public func setUserAgent(_ userAgent: String) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_ua($0, userAgent) })
  }

  // MARK: - PERFORM

  /// An odd type-erasure for `CURLClientDelegate`
  /// to avoid using generics in `@convention(c)` closure.
  private final class _UserInfo {
    class _DelegatePointerBox {
      var requestHeaderFields: Array<CURLHeaderField>? {
        fatalError("Must be overridden.")
      }

      var hasRequestBody: Bool {
        fatalError("Must be overridden.")
      }

      func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
        fatalError("Must be overridden.")
      }

      func setResponseCode(_ responseCode: CURLResponseCode) {
        fatalError("Must be overridden.")
      }

      func appendResponseHeaderField(_ responseHeaderField: CURLHeaderField) {
        fatalError("Must be overridden.")
      }

      func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
        fatalError("Must be overridden.")
      }
    }

    private class _DelegatePointer<Delegate>: _DelegatePointerBox where Delegate: CURLClientDelegate {
      private let _pointer: UnsafeMutablePointer<Delegate>
      init(_ pointer: UnsafeMutablePointer<Delegate>) {
        self._pointer = pointer
      }

      override var requestHeaderFields: Array<CURLHeaderField>? {
        return _pointer.pointee.requestHeaderFields
      }

      override var hasRequestBody: Bool {
        return _pointer.pointee.hasRequestBody
      }

      override func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
        return _pointer.pointee.readNextPartialRequestBody(buffer, maxLength: maxLength)
      }

      override func setResponseCode(_ responseCode: CURLResponseCode) {
        _pointer.pointee.setResponseCode(responseCode)
      }

      override func appendResponseHeaderField(_ responseHeaderField: CURLHeaderField) {
        _pointer.pointee.appendResponseHeaderField(responseHeaderField)
      }

      override func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
        return _pointer.pointee.writeNextPartialResponseBody(bodyPart, length: length)
      }
    }

    let delegatePointer: _DelegatePointerBox

    var responseCode: CURLResponseCode? = nil

    var lastResponseHeaderField: CURLHeaderField? = nil

    init<Delegate>(_ delegatePointer: UnsafeMutablePointer<Delegate>) where Delegate: CURLClientDelegate {
      self.delegatePointer = _DelegatePointer<Delegate>(delegatePointer)
    }
  }

  private var _performed: Bool = false

  /// Call `curl_easy_perform` with the handle.
  public func perform<Delegate>(delegate: inout Delegate) throws where Delegate: CURLClientDelegate {
    if _performed {
      return
    }
    defer { _performed = true }

    // Avoid "⛔️the compiler is unable to type-check this expression in reasonable time" 😓

    func __setRequestHeaderHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws -> UnsafeMutablePointer<CCURLStringList>? {
      guard let requestHeaderFields = userInfoPointer.pointee.delegatePointer.requestHeaderFields else {
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
      guard userInfoPointer.pointee.delegatePointer.hasRequestBody else { return }
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
          ).pointee.delegatePointer.readNextPartialRequestBody(
            buffer,
            maxLength: maxLength
          ) ?? -1
        }
      }
    }

    func __setResponseCodeHeaderHandler(_ userInfoPointer: UnsafeMutablePointer<_UserInfo>) throws {
      /// - Returns: `true` if `line` is `status-line`.
      func ___handleStatusLine(
        _ line: UnsafeMutablePointer<CChar>,
        length: CSize,
        userInfoPointer: UnsafeMutablePointer<_UserInfo>
      ) -> Bool {
        // See https://datatracker.ietf.org/doc/html/rfc9112#section-4
        guard
          length >= 5,
          userInfoPointer.pointee.responseCode == nil,
          userInfoPointer.pointee.lastResponseHeaderField == nil,
          line[0] == 0x48, line[1] == 0x54, line[2] == 0x54, line[3] == 0x50, line[4] == 0x2F // "HTTP/"
        else {
          return false
        }

        var firstSpaceIndex: CSize? = nil
        for ii in 5..<length {
          if line[ii] == 0x20 {
            firstSpaceIndex = ii
            break
          }
        }
        func ____isDigit(_ char: CChar) -> Bool {
          return 0x30 <= char && char <= 0x39
        }
        guard let firstSpaceIndex,
              firstSpaceIndex + 3 < length,
              ____isDigit(line[firstSpaceIndex + 1]),
              ____isDigit(line[firstSpaceIndex + 2]),
              ____isDigit(line[firstSpaceIndex + 3]),
              (firstSpaceIndex + 4 == length || !____isDigit(line[firstSpaceIndex + 4]))
        else {
          return false
        }

        let responseCode: CURLResponseCode = (
          CURLResponseCode(line[firstSpaceIndex + 1] - 0x30) * 100 +
          CURLResponseCode(line[firstSpaceIndex + 2] - 0x30) * 10  +
          CURLResponseCode(line[firstSpaceIndex + 3] - 0x30)
        )
        userInfoPointer.pointee.responseCode = responseCode
        userInfoPointer.pointee.delegatePointer.setResponseCode(responseCode)
        return true
      }

      /// - Returns: `true` if successful.
      func ___handleFolededHeader(
        _ line: String,
        length: CSize,
        userInfoPointer: UnsafeMutablePointer<_UserInfo>
      ) -> Bool {
        guard let lastField = userInfoPointer.pointee.lastResponseHeaderField else {
          return false
        }
        userInfoPointer.pointee.lastResponseHeaderField = (
          name: lastField.name,
          value: "\(lastField.value) \(line._trimmedHeaderLine)"
        )
        return true
      }

      try _throwIfFailed {
        _NWG_curl_easy_set_header_user_info($0, UnsafeMutableRawPointer(userInfoPointer))
      }

      try _throwIfFailed {
        _NWG_curl_easy_set_header_callback($0) { (line, _, length, maybePointer) -> CSize in
          guard let userInfoPointer = maybePointer?.assumingMemoryBound(to: _UserInfo.self) else {
            return -1
          }

          // Skip if empty
          if length == 0 || line.pointee == 0 {
            return length
          }

          // Skip if `line` is status line.
          // https://datatracker.ietf.org/doc/html/rfc9112#section-4
          if ___handleStatusLine(line, length: length, userInfoPointer: userInfoPointer) {
            return length
          }

          guard let lineString = String(
            data: Data(bytesNoCopy: line, count: length, deallocator: .none),
            encoding: .utf8
          ) else {
            return -1
          }

          // Folded header (actually deprecated...)
          if lineString.first!.isWhitespace {
            guard ___handleFolededHeader(lineString, length: length, userInfoPointer: userInfoPointer) else {
              return -1
            }
          } else {
            if let lastField = userInfoPointer.pointee.lastResponseHeaderField {
              userInfoPointer.pointee.delegatePointer.appendResponseHeaderField(lastField)
              userInfoPointer.pointee.lastResponseHeaderField = nil
            }
            let nameAndValue = lineString.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard nameAndValue.count == 2 else {
              return -1
            }
            userInfoPointer.pointee.lastResponseHeaderField = (
              name: String(nameAndValue[0]._trimmedHeaderLine),
              value: String(nameAndValue[1]._trimmedHeaderLine)
            )
          }
          return length
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
          return userInfoPointer.pointee.delegatePointer.writeNextPartialResponseBody(chunk, length: length)
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

        var userInfo = _UserInfo(delegatePointer)
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

      // Response Code & Response Header & Response Body
      // Response Code & Header
      try __setResponseCodeHeaderHandler(userInfoPointer)
      defer {
        if let lastResponseHeaderField = userInfoPointer.pointee.lastResponseHeaderField {
          userInfoPointer.pointee.delegatePointer.appendResponseHeaderField(lastResponseHeaderField)
        }
      }

      // Response Body
      try __setResponseBodyHandler(userInfoPointer)

      // PERFORM!
      try _throwIfFailed({ _NWG_curl_easy_perform($0) })

      // Response Code if missing
      if userInfoPointer.pointee.responseCode == nil {
        let responseCodePointer = UnsafeMutablePointer<CLong>.allocate(capacity: 1)
        defer {
          userInfoPointer.pointee.delegatePointer.setResponseCode(responseCodePointer.pointee)
          responseCodePointer.deallocate()
        }
        try _throwIfFailed({ _NWG_curl_easy_get_response_code($0, responseCodePointer) })
      }
    }
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
