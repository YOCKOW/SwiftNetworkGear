/* *************************************************************************************************
 CURLClientUserInfo.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CLibCURL
import Foundation
import TemporaryFile
import yExtensions

private final class _RequestBodyCache {
  enum _Error: Error {
    case failedToReadDataFromInMemoryFile
  }

  private static let _threshold: Int = 5 * 1024 * 1024

  private var _fh: any FileHandleProtocol

  init(requestBodySize: Int?) throws {
    if let requestBodySize, requestBodySize > _RequestBodyCache._threshold {
      _fh = try TemporaryFile()
    } else {
      _fh = InMemoryFile()
    }
  }

  func write(from buffer: UnsafeMutablePointer<CChar>, count: Int) throws {
    if case let inMemoryFile as InMemoryFile = _fh,
       try inMemoryFile.offset() > _RequestBodyCache._threshold {
      // Switch to `TemporaryFile`.
      let file = try TemporaryFile()
      try inMemoryFile.seek(toOffset: 0)
      guard let availableData = try inMemoryFile.readToEnd() else {
        throw _Error.failedToReadDataFromInMemoryFile
      }
      try file.write(contentsOf: availableData)
      _fh = file
    }

    try buffer.withMemoryRebound(to: UInt8.self, capacity: count) {
      try _fh.write(contentsOf: UnsafeBufferPointer<UInt8>(start: $0, count: count))
    }
  }

  func read(upToCount: Int) throws -> Data? {
    return try _fh.read(upToCount: upToCount)
  }

  func offset() throws -> UInt64 {
    return try _fh.offset()
  }

  func seekToStart() throws {
    try _fh.seek(toOffset: 0)
  }

  func seek(toOffset offset: UInt64) throws {
    try _fh.seek(toOffset: offset)
  }

  @discardableResult
  func seekToEnd() throws -> UInt64 {
    return try _fh.seekToEnd()
  }
}

struct StatusLine {
  let httpVersion: (major: Int, minor: Int?)
  let responseCode: CURLResponseCode

  /// Parse status-line *loosely*.
  init?(line: UnsafeMutablePointer<CChar>, length: CSize) {
    var position = 5 // Skip "HTTP/"

    func __currentByteIsDigit() -> Bool {
      return 0x30 <= line[position] && line[position] <= 0x39
    }

    func __currentByteIsDot() -> Bool {
      return line[position] == 0x2E
    }

    func __currentByteIsSpace() -> Bool {
      return line[position] == 0x20
    }

    func __parseInteger() -> Int? {
      var result: Int? = nil
      while position < length {
        guard __currentByteIsDigit() else { break }
        let value = Int(line[position] - 0x30)
        result = result.map({ $0 * 10 + value }) ?? value
        position += 1
      }
      return result
    }

    func __skipSpaces() {
      while position < length {
        guard __currentByteIsSpace() else { break }
        position += 1
      }
    }

    guard let httpVersionMajor = __parseInteger() else { return nil }
    let httpVersionMinor: Int? = ({ () -> Int? in
      guard __currentByteIsDot() else { return nil }
      position += 1
      return __parseInteger()
    })()
    __skipSpaces()
    guard let responseCode = __parseInteger().map({ CURLResponseCode($0) }),
          responseCode >= 100, responseCode < 600 else {
      return nil
    }

    // Discard reason phrase.

    self.httpVersion = (httpVersionMajor, httpVersionMinor)
    self.responseCode = responseCode
  }
}

/// An odd type-erasure for `CURLClientDelegate`
/// to avoid using generics in `@convention(c)` closure.
internal final class _UserInfo {
  private class _DelegatePointerBox {
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

  private let _delegatePointer: _DelegatePointerBox

  private let _requestBodySize: Int?

  private let _requestBodyCache: _RequestBodyCache?

  private let _maxNumberOfRedirectsAllowed: Int

  /// Increment when receiving status line.
  private var _responseCount: Int = 0

  private var _responseCodeIs3xx: Bool = false

  private var _responseCode: CURLResponseCode? = nil {
    didSet {
      _responseCodeIs3xx = _responseCode.map({ $0 / 100 == 3 }) ?? false
    }
  }

  private var _isFinalDestination: Bool {
    return !_responseCodeIs3xx || _maxNumberOfRedirectsAllowed + 1 == _responseCount
  }

  private var _lastResponseHeaderField: CURLHeaderField? = nil

  var requestHeaderFields: Array<CURLHeaderField>? {
    return _delegatePointer.requestHeaderFields
  }

  var hasRequestBody: Bool {
    return _delegatePointer.hasRequestBody
  }

  func readNextPartialRequestBody(_ buffer: UnsafeMutablePointer<CChar>, maxLength: CSize) -> CSize {
    assert(hasRequestBody, "Unexpected call in spite of missing request body?!")
    do {
      if _responseCount == 0 {
        let actualLength = _delegatePointer.readNextPartialRequestBody(buffer, maxLength: maxLength)
        if _maxNumberOfRedirectsAllowed == 0 {
          return actualLength
        }
        guard let requestBodyCache = _requestBodyCache else {
          fatalError("Missing _RequestBodyCache instance?!")
        }
        try requestBodyCache.write(from: buffer, count: Int(actualLength))
        return actualLength
      }

      assert(_responseCount > 0)
      guard let requestBodyCache = _requestBodyCache else {
        fatalError("Missing _RequestBodyCache instance?!")
      }
      guard let data = try requestBodyCache.read(upToCount: Int(maxLength)) else {
        return -1
      }
      buffer.withMemoryRebound(to: UInt8.self, capacity: Int(maxLength)) {
        data.copyBytes(to: $0, count: data.count)
      }
      return CSize(data.count)
    } catch {
      return -1
    }
  }

  /// - Returns:
  ///    `true` indicates `CURL_SEEKFUNC_OK`,
  ///    `false` indicates `CURL_SEEKFUNC_CANTSEEK`, or
  ///    throwing an error indicates `CURL_SEEKFUNC_FAIL`.
  func rewindRequestBody(toOffset offset: UInt64, from origin: NWGCURLSeekOrigin) throws -> Bool {
    guard _responseCount > 0 else {
      return false
    }
    guard let requestBodyCache = _requestBodyCache else {
      return false
    }
    switch origin {
    case NWGCURLSeekOriginStart:
      try requestBodyCache.seek(toOffset: offset)
    case NWGCURLSeekOriginCurrent:
      try requestBodyCache.seek(toOffset: requestBodyCache.offset() + offset)
    case NWGCURLSeekOriginEnd:
      let endOffset = try requestBodyCache.seekToEnd()
      try requestBodyCache.seek(toOffset: endOffset + offset)
    default:
      return false
    }
    return true
  }

  /// - Returns: `true` if the given `line` is successfully handled.
  func handleResponseHeaderLine(_ line: UnsafeMutablePointer<CChar>, length: CSize) throws -> Bool {
    // Skip if empty
    if length == 0 || line[0] == 0 || (length == 2 && line[0] == 0x0D && line[1] == 0x0A) {
      return true
    }

    // Status Line
    if (
      length >= 5 &&
      line[0] == 0x48 && line[1] == 0x54 && line[2] == 0x54 && line[3] == 0x50 && line[4] == 0x2F // "HTTP/"
    ) {
      guard let statusLine = StatusLine(line: line, length: length) else {
        return false
      }
      _responseCount += 1
      _responseCode = statusLine.responseCode
      if let requestBodyCache = _requestBodyCache {
        try requestBodyCache.seekToStart()
      }
      if _isFinalDestination {
        _delegatePointer.setResponseCode(statusLine.responseCode)
      }
      return true
    }

    // -- Not status line
    // Discard any field if it's not final destination.
    guard _isFinalDestination else {
      return true
    }

    guard let lineString = String(
      data: Data(bytesNoCopy: line, count: length, deallocator: .none),
      encoding: .utf8
    ) else {
      return false
    }
    assert(!lineString.isEmpty)

    // Folded header (actually deprecated)
    if lineString.first!.isWhitespace {
      guard let lastField = _lastResponseHeaderField else {
        return false
      }
      _lastResponseHeaderField = (
        name: lastField.name,
        value: "\(lastField.value) \(lineString._trimmedHeaderLine)"
      )
      return true
    }

    // Usual header field
    if let lastField = _lastResponseHeaderField {
      _delegatePointer.appendResponseHeaderField(lastField)
      _lastResponseHeaderField = nil
    }
    guard case let (name, value?) = lineString.splitOnce(separator: ":") else {
      return false
    }
    _lastResponseHeaderField = (
      name: String(name._trimmedHeaderLine),
      value: String(value._trimmedHeaderLine)
    )
    return true
  }

  private func _finalizeResponseHeader() {
    guard let lastResponseHeaderField = _lastResponseHeaderField else {
      return
    }
    _delegatePointer.appendResponseHeaderField(lastResponseHeaderField)
    _lastResponseHeaderField = nil
  }

  func writeNextPartialResponseBody(_ bodyPart: UnsafeMutablePointer<CChar>, length: CSize) -> CSize {
    assert(_responseCode != nil, "Missing response code?!")
    assert(_responseCount > 0, "Not incremented response count?!")

    // Call delegate's `writeNextPartialResponseBody` only if it is final destination
    guard _isFinalDestination else { return length }
    _finalizeResponseHeader()
    return _delegatePointer.writeNextPartialResponseBody(bodyPart, length: length)
  }

  init<Delegate>(
    delegatePointer: UnsafeMutablePointer<Delegate>,
    requestBodySize: Int?,
    maxNumberOfRedirectsAllowed: Int
  ) throws where Delegate: CURLClientDelegate {
    self._delegatePointer = _DelegatePointer<Delegate>(delegatePointer)
    self._requestBodySize = requestBodySize
    self._requestBodyCache = (
      delegatePointer.pointee.hasRequestBody && maxNumberOfRedirectsAllowed != 0
    ) ? try _RequestBodyCache(requestBodySize: requestBodySize) : nil
    self._maxNumberOfRedirectsAllowed = maxNumberOfRedirectsAllowed
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
