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

public protocol CURLResponseBodyReceiver {
  /// Receives a part of response body.
  ///
  /// - returns: The number of bytes actually received.
  mutating func receive(chunk: UnsafePointer<CChar>, length: size_t) -> size_t
}

extension Data: CURLResponseBodyReceiver {
  @inlinable
  public mutating func receive(chunk: UnsafePointer<CChar>, length: size_t) -> size_t {
    self.append(UnsafeRawPointer(chunk).assumingMemoryBound(to: UInt8.self), count: length)
    return length
  }
}

extension OutputStream: CURLResponseBodyReceiver {
  @inlinable
  public func receive(chunk: UnsafePointer<CChar>, length: size_t) -> size_t {
    return self.write(
      UnsafeRawPointer(chunk).assumingMemoryBound(to: UInt8.self),
      maxLength: length
    )
  }
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

  /// Returns the content of the response body after `prform()`ed
  /// if the type of its receiver is `Data`.
  public var responseBody: Data? {
    return _responseBody
  }

  /// An odd type-erasure to pass the pointer of an instance of `CURLResponseBodyReceiver` to C-API.
  private final class _ResponseBodyPointerContainer {
    private class _Box {
      func receive(chunk: UnsafePointer<CChar>, length: size_t) -> size_t {
        return -1
      }
    }
    private final class _BasePointer<T>: _Box where T: CURLResponseBodyReceiver {
      private let _pointer: UnsafeMutablePointer<T>
      init(_ pointer: UnsafeRawBufferPointer) {
        self._pointer = UnsafeMutablePointer(
          mutating: pointer.baseAddress!.assumingMemoryBound(to: T.self)
        )
      }
      override func receive(chunk: UnsafePointer<CChar>, length: size_t) -> size_t {
        return _pointer.pointee.receive(chunk: chunk, length: length)
      }
    }

    private let _pointerBox: _Box

    init<T>(_ pointer: UnsafeRawBufferPointer, of type: T.Type) where T: CURLResponseBodyReceiver {
      self._pointerBox = _BasePointer<T>(pointer)
    }

    func receive(chunk: UnsafePointer<CChar>, length: size_t) -> size_t {
      return _pointerBox.receive(chunk: chunk, length: length)
    }
  }


  /// Call `curl_easy_perform` with the handle.
  ///
  /// - parameters:
  ///    * responseBody: A stream-like object that the response body willl be written to.
  public func perform<ResponseBody>(
    responseBody: inout ResponseBody
  ) throws where ResponseBody: CURLResponseBodyReceiver {
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

            // Skip if empty
            if length == 0 || line.pointee == 0 {
              return length
            }
            // Skip if prefix is "HTTP/"
            if length >= 5 {
              let prefixIsHTTP: Bool = ({
                guard $0[0] == 0x48 || $0[0] == 0x68 else { return false } // H
                guard $0[1] == 0x54 || $0[1] == 0x74 else { return false } // T
                guard $0[2] == 0x54 || $0[2] == 0x74 else { return false } // T
                guard $0[3] == 0x50 || $0[3] == 0x70 else { return false } // P
                guard $0[4] == 0x2F else { return false } // <slash>
                return true
              })(line)
              if prefixIsHTTP {
                return length
              }
            }

            guard let lineString = String(
              data: Data(bytesNoCopy: line, count: length, deallocator: .none),
              encoding: .utf8
            ) else {
              return -1
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
        // ⚠️ Avoid "A C function pointer cannot be formed from a closure that captures generic parameters" error.
        var responseBodyContainer = _ResponseBodyPointerContainer(responseBodyPointer, of: ResponseBody.self)
        try withUnsafeBytes(of: &responseBodyContainer) { (responseBodyContainerPointer) -> Void in
          try _throwIfFailed {
            _NWG_curl_easy_set_write_user_info(
              $0,
              UnsafeMutableRawPointer(mutating: responseBodyContainerPointer.baseAddress!)
            )
          }
          try _throwIfFailed {
            _NWG_curl_easy_set_write_function($0) { (chunk, _, length, maybeContainerPointer) -> size_t in
              guard let responseBodyContainerPointer = maybeContainerPointer else { return -1 }
              return responseBodyContainerPointer.assumingMemoryBound(
                to: _ResponseBodyPointerContainer.self
              ).pointee.receive(
                chunk: chunk,
                length: length
              )
            }
          }
          try _throwIfFailed({ _NWG_curl_easy_perform($0) })
        }
      }
    }

    let responseCodePointer = UnsafeMutablePointer<CLong>.allocate(capacity: 1)
    defer { responseCodePointer.deallocate() }
    try _throwIfFailed({ _NWG_curl_easy_get_response_code($0, responseCodePointer) })

    _responseCode = Int(responseCodePointer.pointee)
    _responseHeaders = responseHeaders
    _responseBody = responseBody as? Data
    _performed = true
  }

  /// Execute `perform(responseBody:)` with setting its `responseBody` to an instance of `Data`.
  @discardableResult
  public func perform() throws -> Data {
    var responseBody = Data()
    try self.perform(responseBody: &responseBody)
    return responseBody
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
