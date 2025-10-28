/* *************************************************************************************************
 CURLClientDelegate.swift
   © 2024-2025 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CLibCURL
import Dispatch
import Foundation

public typealias CURLHeaderField = (name: String, value: String)

/// A delegate that is used during client's `perform()`ing.
public protocol CURLClientDelegate: Sendable, AnyObject {
  func willStartPerforming(client: EasyClient) async throws

  func didFinishPerforming(client: EasyClient) async throws

  var requestHeaderFields: Array<CURLHeaderField>? { get }

  var hasRequestBody: Bool { get }

  /// Sends a part of request body.
  /// The data area pointed at by `buffer` should be filled up with
  /// at most `maxLength` number of bytes by your function.
  ///
  /// - Returns: The actual number of bytes that it stored in the data area pointed at
  ///            by the pointer `buffer`.
  func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize

  func setResponseCode(_ responseCode: CURLResponseCode)

  func appendResponseHeaderField(_ responseHeaderField: CURLHeaderField)

  /// Receives a part of response body.
  ///
  /// - Returns: The number of bytes actually received.
  func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize
}

public protocol CURLRequestBodySender {
  /// Sends a part of request body.
  /// The data area pointed at by `buffer` should be filled up with
  /// at most `maxLength` number of bytes by your function.
  ///
  /// - Returns: The actual number of bytes that it stored in the data area pointed at
  ///            by the pointer `buffer`.
  mutating func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize
}

public protocol CURLResponseBodyReceiver {
  /// Receives a part of response body.
  ///
  /// - Returns: The number of bytes actually received.
  mutating func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize
}

/// A simple implementation of `CURLClientDelegate`.
open class CURLClientGeneralDelegate: CURLClientDelegate, @unchecked Sendable {
  ///  A wrapper of `CURLRequestBodySender` or something like that.
  public struct RequestBody: Sendable {
    private class _RequestBodyBase: @unchecked Sendable {
      func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
        return -1
      }
    }

    private class _SomeRequestBodySender<T>: _RequestBodyBase, @unchecked Sendable where T: CURLRequestBodySender {
      var _base: T
      init(_ base: T) {
        self._base = base
      }
      override func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
        return _base.readNextPartialRequestBody(buffer, maxLength: maxLength)
      }
    }

    private final class _InputStream: _RequestBodyBase, @unchecked Sendable {
      private let stream: InputStream
      init(_ stream: InputStream) {
        self.stream = stream
      }
      override func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
        return buffer.withMemoryRebound(to: UInt8.self, capacity: maxLength) {
          return stream.read($0, maxLength: maxLength)
        }
      }
    }

    private final class _Data: _RequestBodyBase, @unchecked Sendable {
      private var data: Data
      private var currentIndex: Data.Index
      init(_ data: Data ) {
        self.data = data
        self.currentIndex = data.startIndex
      }
      override func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
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

    private final class _SomeDataProtocol<T>: _RequestBodyBase, @unchecked Sendable where T: DataProtocol {
      private var data: T
      private var currentIndex: T.Index
      init(_ data: T) {
        self.data = data
        self.currentIndex = data.startIndex
      }
      override func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
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

    private final class _SomeAsyncSequence<T>: _RequestBodyBase,
                                               @unchecked Sendable where T: AsyncSequence,
                                                                         T: Sendable,
                                                                         T.AsyncIterator: Sendable,
                                                                         T.Element == UInt8 {
      private var iterator: T.AsyncIterator
      init(_ sequence: T) {
        self.iterator = sequence.makeAsyncIterator()
      }

      private var _currentBuffer: UnsafeMutablePointer<UInt8>!
      private var _currentCount: size_t!
      override func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
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
    
    private final class _SomeSequence<T>: _RequestBodyBase, @unchecked Sendable where T: Sequence, T.Element == UInt8 {
      var iterator: T.Iterator
      init(_ sequence: T) {
        self.iterator = sequence.makeIterator()
      }
      override func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
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

    private let _base: _RequestBodyBase

    fileprivate mutating func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
      return _base.readNextPartialRequestBody(buffer, maxLength: maxLength)
    }

    public init<T>(_ sender: T) where T: CURLRequestBodySender {
      self._base = _SomeRequestBodySender<T>(sender)
    }

    public init(stream: InputStream) {
      self._base = _InputStream(stream)
    }

    public init(data: Data) {
      self._base = _Data(data)
    }

    public init<D>(data: D) where  D: DataProtocol {
      self._base = _SomeDataProtocol<D>(data)
    }

    public init<A>(_ sequence: A) where A: AsyncSequence,
                                        A: Sendable,
                                        A.AsyncIterator: Sendable,
                                        A.Element == UInt8 {
      self._base = _SomeAsyncSequence<A>(sequence)
    }

    public init<S>(_ sequence: S) where S: Sequence, S.Element == UInt8 {
      self._base = _SomeSequence<S>(sequence)
    }
  }

  public struct ResponseBody {
    fileprivate class _ResponseBodyBase {
      var base: Any {
        fatalError("Must be overridden.")
      }

      func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
        return -1
      }
    }

    private final class _SomeResponseBodyReceiver<T>: _ResponseBodyBase where T: CURLResponseBodyReceiver {
      private var _base: T
      
      override var base: Any {
        return _base
      }

      init(_ base: T) {
        self._base = base
      }

      override func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
        return _base.writeNextPartialResponseBody(bodyPart, length: length)
      }
    }

    private final class _SomeCollection<C>: _ResponseBodyBase where C: RangeReplaceableCollection, C.Element == UInt8 {
      private var _collection: C

      override var base: Any {
        return _collection
      }

      init(_ collection: C) {
        self._collection = collection
      }


      override func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
        bodyPart.withMemoryRebound(to: UInt8.self, capacity: Int(length)) {
          for ii in 0..<length {
            _collection.append($0[ii])
          }
        }
        return length
      }
    }

    fileprivate let _base: _ResponseBodyBase

    fileprivate mutating func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
      return _base.writeNextPartialResponseBody(bodyPart, length: length)
    }

    public init(data: Data) {
      self._base = _SomeResponseBodyReceiver<Data>(data)
    }

    public init() {
      self.init(data: Data())
    }

    public init(stream: OutputStream) {
      self._base = _SomeResponseBodyReceiver<OutputStream>(stream)
    }

    public init<T>(_ receiver: T) where T: CURLResponseBodyReceiver {
      self._base = _SomeResponseBodyReceiver<T>(receiver)
    }

    public init<C>(_ collection: C) where C: RangeReplaceableCollection, C.Element == UInt8 {
      self._base = _SomeCollection(collection)
    }
  }

  public enum Error: Swift.Error {
    case requestHasNotStarted
    case requestIsOngoing
    case requestFinished
  }

  private struct _State {
    var isPerforming: Bool
    var didFinish: Bool
  }
  private var __state: _State
  private let _stateQueue: DispatchQueue = .init(
    label: "jp.YOCKOW.CURLClient.CURLClientGeneralDelegate.\(UUID().uuidString)",
    attributes: .concurrent
  )
  private func _withState<T>(_ work: (inout _State) throws -> T) rethrows -> T {
    return try _stateQueue.sync(flags: .barrier) { try work(&__state) }
  }

  open var isPerforming: Bool {
    return _withState(\.isPerforming)
  }

  open var didFinish: Bool {
    return _withState(\.didFinish)
  }

  open func willStartPerforming(client: EasyClient) throws {
    try _withState {
      if $0.isPerforming { throw Error.requestIsOngoing }
      if $0.didFinish { throw Error.requestFinished }
      $0.isPerforming = true
    }
  }

  open func didFinishPerforming(client: EasyClient) throws {
    try _withState {
      guard $0.isPerforming else { throw Error.requestHasNotStarted }
      $0.isPerforming = false
      $0.didFinish = true
    }
  }


  open var requestHeaderFields: Array<CURLHeaderField>?

  private var _requestBody: RequestBody?

  open var hasRequestBody: Bool {
    return _requestBody != nil
  }

  open func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
    assert(isPerforming)
    return _requestBody?.readNextPartialRequestBody(buffer, maxLength: maxLength) ?? -1
  }

  open private(set) var responseCode: CURLResponseCode!

  open func setResponseCode(_ responseCode: CURLResponseCode) {
    assert(isPerforming)
    self.responseCode = responseCode
  }

  public private(set) var responseHeaderFields: Array<CURLHeaderField> = []

  open func appendResponseHeaderField(_ responseHeaderField: CURLHeaderField) {
    assert(isPerforming)
    responseHeaderFields.append(responseHeaderField)
  }

  private var _responseBody: ResponseBody

  open func responseBody<T>(`as` type: T.Type) -> T? {
    return _responseBody._base.base as? T
  }

  open func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
    assert(isPerforming)
    return _responseBody.writeNextPartialResponseBody(bodyPart, length: length)
  }

  public init(
    requestHeaderFields: Array<CURLHeaderField>? = nil,
    requestBody: RequestBody? = nil,
    responseBody: ResponseBody = .init()
  ) {
    self.__state = .init(isPerforming: false, didFinish: false)
    self.requestHeaderFields = requestHeaderFields
    self._requestBody = requestBody
    self._responseBody = responseBody
  }
}

extension Data: CURLResponseBodyReceiver {
  @inlinable
  public mutating func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
    self.append(UnsafeRawPointer(bodyPart).assumingMemoryBound(to: UInt8.self), count: length)
    return length
  }
}

extension OutputStream: CURLResponseBodyReceiver {
  @inlinable
  public func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
    return self.write(
      UnsafeRawPointer(bodyPart).assumingMemoryBound(to: UInt8.self),
      maxLength: length
    )
  }
}
