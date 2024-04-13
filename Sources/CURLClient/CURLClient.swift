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

  public func setHTTPMethodToGet() throws {
    try _throwIfFailed({ _NWG_curl_easy_set_http_method_to_get($0) })
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

  private struct _ResponseHeaderInfo<Delegate> {
    let delegatePointer: UnsafeMutablePointer<Delegate>
    var responseCode: CURLResponseCode? = nil
    var lastResponseHeaderField: CURLHeaderField? = nil
    init(delegatePointer: UnsafeMutablePointer<Delegate>) {
      self.delegatePointer = delegatePointer
    }
  }

  private var _performed: Bool = false

  /// Call `curl_easy_perform` with the handle.
  public func perform<Delegate>(delegate: inout Delegate) throws where Delegate: CURLClientDelegate {
    if _performed {
      return
    }
    defer { _performed = true }

    typealias _Delegate = (any CURLClientDelegate)

    func __setRequestHeaderHandler(_ delegatePointer: UnsafeMutablePointer<_Delegate>) throws -> UnsafeMutablePointer<CCURLStringList>? {
      guard let requestHeaderFields = delegatePointer.pointee.requestHeaderFields else {
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

    func __setRequestBodyHandler(_ delegatePointer: UnsafeMutablePointer<_Delegate>) throws {
      guard delegatePointer.pointee.hasRequestBody else { return }
      try _throwIfFailed {
        _NWG_curl_easy_set_read_user_info($0, UnsafeMutableRawPointer(delegatePointer))
      }
      try _throwIfFailed {
        _NWG_curl_easy_set_read_function($0) { (buffer,
                                                _,
                                                maxLength,
                                                maybePointer) -> CSize in
          return maybePointer?.assumingMemoryBound(
            to: _Delegate.self
          ).pointee.readNextPartialRequestBody(
            buffer,
            maxLength: maxLength
          ) ?? -1
        }
      }
    }

    func __setResponseCodeHeaderHandler(_ responseHeaderInfoPointer: UnsafeMutablePointer<_ResponseHeaderInfo<_Delegate>>) throws {
      try _throwIfFailed {
        _NWG_curl_easy_set_header_user_info($0, UnsafeMutableRawPointer(responseHeaderInfoPointer))
      }
      try _throwIfFailed {
        _NWG_curl_easy_set_header_callback($0) { (line, _, length, maybePointer) -> CSize in
          guard let responseHeaderInfoPointer = maybePointer?.assumingMemoryBound(
            to: _ResponseHeaderInfo<_Delegate>.self
          ) else {
            return -1
          }
          let delegatePointer = responseHeaderInfoPointer.pointee.delegatePointer

          // Skip if empty
          if length == 0 || line.pointee == 0 {
            return length
          }

          // Skip if `line` is status line.
          // https://datatracker.ietf.org/doc/html/rfc9112#section-4
          if length >= 5 {
            let prefixIsHTTP: Bool = ({
              guard $0[0] == 0x48 else { return false } // H
              guard $0[1] == 0x54 else { return false } // T
              guard $0[2] == 0x54 else { return false } // T
              guard $0[3] == 0x50 else { return false } // P
              guard $0[4] == 0x2F else { return false } // <slash>
              return true
            })(line)
            if prefixIsHTTP {
              DETERMINE_RESPONSE_CODE_IF_POSSIBLE: do {
                var firstSpaceIndex: CSize? = nil
                for ii in 5..<length {
                  if line[ii] == 0x20 {
                    firstSpaceIndex = ii
                    break
                  }
                }
                func __isDigit(_ char: CChar) -> Bool {
                  return 0x30 <= char && char <= 0x39
                }
                guard let firstSpaceIndex,
                      firstSpaceIndex + 3 < length,
                      __isDigit(line[firstSpaceIndex + 1]),
                      __isDigit(line[firstSpaceIndex + 2]),
                      __isDigit(line[firstSpaceIndex + 3]),
                      (firstSpaceIndex + 4 == length || !__isDigit(line[firstSpaceIndex + 4]))
                else {
                  break DETERMINE_RESPONSE_CODE_IF_POSSIBLE
                }
                let responseCode: CURLResponseCode = (
                  CURLResponseCode(line[firstSpaceIndex + 1] - 0x30) * 100 +
                  CURLResponseCode(line[firstSpaceIndex + 2] - 0x30) * 10  +
                  CURLResponseCode(line[firstSpaceIndex + 3] - 0x30)
                )
                responseHeaderInfoPointer.pointee.responseCode = responseCode
                delegatePointer.pointee.setResponseCode(responseCode)
              }
              return length
            }
          }

          guard let lineString = String(
            data: Data(bytesNoCopy: line, count: length, deallocator: .none),
            encoding: .utf8
          ) else {
            return -1
          }

          // Folded header (actually deprecated...)
          if lineString.first!.isWhitespace {
            guard let lastField = responseHeaderInfoPointer.pointee.lastResponseHeaderField else {
              return -1
            }
            responseHeaderInfoPointer.pointee.lastResponseHeaderField = (
              name: lastField.name,
              value: "\(lastField.value) \(lineString._trimmedHeaderLine)"
            )
          } else {
            if let lastField = responseHeaderInfoPointer.pointee.lastResponseHeaderField {
              delegatePointer.pointee.appendResponseHeaderField(lastField)
              responseHeaderInfoPointer.pointee.lastResponseHeaderField = nil
            }
            let nameAndValue = lineString.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard nameAndValue.count == 2 else {
              return -1
            }
            responseHeaderInfoPointer.pointee.lastResponseHeaderField = (
              name: String(nameAndValue[0]._trimmedHeaderLine),
              value: String(nameAndValue[1]._trimmedHeaderLine)
            )
          }
          return length
        }
      }
    }

    func __setResponseBodyHandler(_ responseHeaderInfoPointer: UnsafeMutablePointer<_ResponseHeaderInfo<_Delegate>>) throws {
      try _throwIfFailed {
        _NWG_curl_easy_set_write_user_info(
          $0,
          UnsafeMutableRawPointer(responseHeaderInfoPointer.pointee.delegatePointer)
        )
      }
      try _throwIfFailed {
        _NWG_curl_easy_set_write_function($0) { (chunk, _, length, maybePointer) -> CSize in
          guard let delegatePointer = maybePointer?.assumingMemoryBound(to: _Delegate.self) else {
            return -1
          }
          return delegatePointer.pointee.writeNextPartialResponseBody(chunk, length: length)
        }
      }
    }

    var existentialDelegate: _Delegate = delegate
    defer {
      delegate = existentialDelegate as! Delegate
    }
    try withUnsafeBytes(of: &existentialDelegate) {
      guard let delegatePointer = UnsafeMutablePointer<_Delegate>(
        mutating: $0.assumingMemoryBound(to: _Delegate.self).baseAddress
      ) else {
        fatalError("Unexpected pointer?!")
      }

      // Request Header
      let requestHeaderFieldCURLList = try __setRequestHeaderHandler(delegatePointer)
      defer {
        _NWG_curl_slist_free_all(requestHeaderFieldCURLList)
      }

      // Request Body
      try __setRequestBodyHandler(delegatePointer)

      // Response Code & Response Header & Response Body
      var responseHeaderInfo = _ResponseHeaderInfo<_Delegate>(delegatePointer: delegatePointer)
      try withUnsafeBytes(of: &responseHeaderInfo) {
        guard let responseHeaderInfoPointer = UnsafeMutablePointer<_ResponseHeaderInfo<_Delegate>>(
          mutating: $0.assumingMemoryBound(to: _ResponseHeaderInfo<_Delegate>.self).baseAddress
        ) else {
          fatalError("Unexpected pointer?!")
        }

        // Response Code & Header
        try __setResponseCodeHeaderHandler(responseHeaderInfoPointer)
        defer {
          if let lastResponseHeaderField = responseHeaderInfoPointer.pointee.lastResponseHeaderField {
            delegatePointer.pointee.appendResponseHeaderField(lastResponseHeaderField)
          }
        }

        // Response Body
        try __setResponseBodyHandler(responseHeaderInfoPointer)

        // PERFORM!
        try _throwIfFailed({ _NWG_curl_easy_perform($0) })

        // Response Code if missing
        if responseHeaderInfoPointer.pointee.responseCode == nil {
          let responseCodePointer = UnsafeMutablePointer<CLong>.allocate(capacity: 1)
          defer {
            delegatePointer.pointee.setResponseCode(responseCodePointer.pointee)
            responseCodePointer.deallocate()
          }
          try _throwIfFailed({ _NWG_curl_easy_get_response_code($0, responseCodePointer) })
        }
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
