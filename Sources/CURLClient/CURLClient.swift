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

public protocol CURLRequestBodySender {
  /// Sends a part of request body.
  /// The data area pointed at by `buffer` should be filled up with
  /// at most `maxLength` number of bytes by your function.
  ///
  /// - Returns: The actual number of bytes that it stored in the data area pointed at
  ///            by the pointer `buffer`.
  mutating func sendChunk(filling buffer: UnsafeMutablePointer<CChar>, maxLength: size_t) -> size_t
}

public struct CURLRequestBodyByteSequence: CURLRequestBodySender {
  private class _SomeSequence {
    func sendChunk(filling buffer: UnsafeMutablePointer<CChar>, maxLength: size_t) -> size_t {
      return -1
    }
  }
  private final class _Data: _SomeSequence {
    private var data: Data
    private var currentIndex: Data.Index
    init(_ data: Data ) {
      self.data = data
      self.currentIndex = data.startIndex
    }
    override func sendChunk(filling buffer: UnsafeMutablePointer<CChar>, maxLength: size_t) -> size_t {
      guard currentIndex < data.endIndex else { return 0 }
      let count = min(maxLength, data.endIndex - currentIndex)
      let chunkEndIndex = currentIndex + count
      data.copyBytes(
        to: UnsafeMutableRawPointer(buffer).assumingMemoryBound(to: UInt8.self),
        from: currentIndex..<chunkEndIndex
      )
      currentIndex = chunkEndIndex
      return count
    }
  }
  private final class _OtherData<T>: _SomeSequence where T: DataProtocol {
    private var data: T
    private var currentIndex: T.Index
    init(_ data: T) {
      self.data = data
      self.currentIndex = data.startIndex
    }
    override func sendChunk(filling buffer: UnsafeMutablePointer<CChar>, maxLength: size_t) -> size_t {
      guard currentIndex < data.endIndex else { return 0 }
      var count: size_t = 0
      var chunkEndIndex = currentIndex
      for _ in 0..<maxLength {
        chunkEndIndex = data.index(after: chunkEndIndex)
        count += 1
        if chunkEndIndex == data.endIndex {
          break
        }
      }
      data.copyBytes(
        to: UnsafeMutableBufferPointer(start: buffer, count: Int(maxLength)),
        from: currentIndex..<chunkEndIndex
      )
      return count
    }
  }

  private final class _AsyncSequence<T>: _SomeSequence where T: AsyncSequence, T.Element == UInt8 {
    private var iterator: T.AsyncIterator
    init(_ sequence: T) {
      self.iterator = sequence.makeAsyncIterator()
    }

    private var _currentBuffer: UnsafeMutablePointer<UInt8>!
    private var _currentCount: size_t!
    override func sendChunk(filling buffer: UnsafeMutablePointer<CChar>, maxLength: size_t) -> size_t {
      _currentBuffer = UnsafeMutableRawPointer(buffer).assumingMemoryBound(to: UInt8.self)
      _currentCount = 0

      // Using semahore is generally a bad idea,
      // but in this case (as a libcurl's callback) it isn't unsafe.
      let semaphore = DispatchSemaphore(value: 0)
      Task {
        do {
          for _ in 0..<maxLength {
            guard let byte = try await iterator.next() else {
              break
            }
            _currentBuffer[_currentCount] = byte
            _currentCount += 1
          }
        } catch {
          _currentCount = -1
        }
        semaphore.signal()
      }
      semaphore.wait()
      return _currentCount
    }
  }

  private final class _Other<T>: _SomeSequence where T: Sequence, T.Element == UInt8 {
    var iterator: T.Iterator
    init(_ sequence: T) {
      self.iterator = sequence.makeIterator()
    }
    override func sendChunk(filling buffer: UnsafeMutablePointer<CChar>, maxLength: size_t) -> size_t {
      let uint8Buffer = UnsafeMutableRawPointer(buffer).assumingMemoryBound(to: UInt8.self)
      var count = 0
      for _ in 0..<maxLength {
        guard let byte = iterator.next() else {
          break
        }
        uint8Buffer[count] = byte
        count += 1
      }
      return count
    }
  }

  private let _sequence: _SomeSequence

  public init(_ data: Data) {
    self._sequence = _Data(data)
  }

  public init<D>(_ data: D) where D: DataProtocol {
    self._sequence = _OtherData(data)
  }

  public init<AS>(_ sequence: AS) where AS: AsyncSequence, AS.Element == UInt8 {
    self._sequence = _AsyncSequence(sequence)
  }

  public init<S>(_ sequence: S) where S: Sequence, S.Element == UInt8 {
    self._sequence = _Other<S>(sequence)
  }

  public mutating func sendChunk(filling buffer: UnsafeMutablePointer<CChar>, maxLength: size_t) -> size_t {
    return self._sequence.sendChunk(filling: buffer, maxLength: maxLength)
  }
}

extension InputStream: CURLRequestBodySender {
  @inlinable
  public func sendChunk(filling buffer: UnsafeMutablePointer<CChar>, maxLength: size_t) -> size_t {
    return buffer.withMemoryRebound(to: UInt8.self, capacity: maxLength) {
      return self.read($0, maxLength: maxLength)
    }
  }
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

  public func setHTTPMethodToPost() throws {
    try _throwIfFailed({ _NWG_curl_easy_set_http_method_to_post($0) })
  }

  public func setURL(_ url: URL) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_url($0, url.absoluteString) })
  }

  public func setUserAgent(_ userAgent: String) throws {
    try _throwIfFailed({ _NWG_curl_easy_set_ua($0, userAgent) })
  }

  // MARK: - REQUEST
  public var requestHeaders: Array<(name: String, value: String)>? = nil
  public func setRequestHeaders(_ requestHeaders: Array<(name: String, value: String)>) {
    self.requestHeaders = requestHeaders
  }

  public var requestBody: (any CURLRequestBodySender)? = nil
  public func setRequsetBody<T>(_ requestBody: T) where T: CURLRequestBodySender {
    self.requestBody = requestBody
  }

  // MARK: /REQUEST -

  // MARK: - RESPONSE

  public private(set) var responseCode: Int? = nil

  public private(set) var responseHeaders: Array<(name: String, value: String)>? = nil

  /// The response body that the client will write to during `perform()`ing.
  public var responseBody: any CURLResponseBodyReceiver = Data()
  public func setResponseBody<T>(_ responseBody: T) where T: CURLResponseBodyReceiver {
    self.responseBody = responseBody
  }

  // MARK: /RESPONSE -

  // MARK: - PERFORM

  private var _performed: Bool = false

  /// Call `curl_easy_perform` with the handle.
  public func perform() throws {
    if _performed {
      return
    }
    defer { _performed = true }

    let requestHeaderList: UnsafeMutablePointer<CCURLStringList>? = try requestHeaders.flatMap {
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

    typealias RequestBodyResponseHeadersResponseBody = (
      requestBody: (any CURLRequestBodySender)?,
      responseHeaders: Array<(name: String, value: String)>,
      responseBody: any CURLResponseBodyReceiver
    )
    var reqBodyResHeadersResBodyTuple: RequestBodyResponseHeadersResponseBody = (
      self.requestBody,
      [],
      self.responseBody
    )
    try withUnsafeBytes(of: &reqBodyResHeadersResBodyTuple) {
      guard let reqBodyResHeadersResBodyTuplePointer = $0.assumingMemoryBound(
        to: RequestBodyResponseHeadersResponseBody.self
      ).baseAddress.flatMap({
        UnsafeMutablePointer<RequestBodyResponseHeadersResponseBody>(mutating: $0)
      }) else {
        fatalError("Unexpected Poitner?!")
      }

      REQUEST_BODY: do {
        if reqBodyResHeadersResBodyTuplePointer.pointee.requestBody != nil {
          try _throwIfFailed {
            _NWG_curl_easy_set_read_user_info(
              $0,
              UnsafeMutableRawPointer(mutating: reqBodyResHeadersResBodyTuplePointer)
            )
          }
          try _throwIfFailed {
            _NWG_curl_easy_set_read_function($0) { (buffer, _, maxLength, maybePointer) -> size_t in
              return maybePointer?.assumingMemoryBound(
                to: RequestBodyResponseHeadersResponseBody.self
              ).pointee.requestBody?.sendChunk(filling: buffer, maxLength: maxLength) ?? -1
            }
          }
        }
      }

      RESPONSE_HEADRES: do {
        try _throwIfFailed {
          _NWG_curl_easy_set_header_user_info(
            $0,
            UnsafeMutableRawPointer(mutating: reqBodyResHeadersResBodyTuplePointer)
          )
        }
        try _throwIfFailed {
          _NWG_curl_easy_set_header_callback($0) { (line, _, length, maybePointer) -> size_t in
            guard let reqBodyResHeadersResBodyTuplePointer = maybePointer?.assumingMemoryBound(
              to: RequestBodyResponseHeadersResponseBody.self
            ) else {
              return -1
            }

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

            var responseHeaders = reqBodyResHeadersResBodyTuplePointer.pointee.responseHeaders
            defer { reqBodyResHeadersResBodyTuplePointer.pointee.responseHeaders = responseHeaders }

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
      }

      RESPONSE_BODY: do {
        try _throwIfFailed {
          _NWG_curl_easy_set_write_user_info(
            $0,
            UnsafeMutableRawPointer(mutating: reqBodyResHeadersResBodyTuplePointer)
          )
        }
        try _throwIfFailed {
          _NWG_curl_easy_set_write_function($0) { (chunk, _, length, maybePointer) -> size_t in
            guard let reqBodyResHeadersResBodyTuplePointer = maybePointer?.assumingMemoryBound(
              to: RequestBodyResponseHeadersResponseBody.self
            ) else {
              return -1
            }
            return reqBodyResHeadersResBodyTuplePointer.pointee.responseBody.receive(
              chunk: chunk,
              length: length
            )
          }
        }
      }

      try _throwIfFailed({ _NWG_curl_easy_perform($0) })
    }

    let responseCodePointer = UnsafeMutablePointer<CLong>.allocate(capacity: 1)
    defer { responseCodePointer.deallocate() }
    try _throwIfFailed({ _NWG_curl_easy_get_response_code($0, responseCodePointer) })

    responseCode = Int(responseCodePointer.pointee)
    responseHeaders = reqBodyResHeadersResBodyTuple.responseHeaders
    responseBody = reqBodyResHeadersResBodyTuple.responseBody
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
