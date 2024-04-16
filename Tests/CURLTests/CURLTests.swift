/* *************************************************************************************************
 CURLTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import CURLClient

struct HTTPBinResponse: Decodable {
  enum StringOrArray: Decodable, Equatable, ExpressibleByStringLiteral, ExpressibleByArrayLiteral {
    case string(String)
    case array([String])

    init(from decoder: any Decoder) throws {
      let singleValueContainer = try decoder.singleValueContainer()
      if let string = try? singleValueContainer.decode(String.self) {
        self = .string(string)
        return
      }
      self = .array(try singleValueContainer.decode(Array<String>.self))
    }

    typealias StringLiteralType = String
    init(stringLiteral value: String) {
      self = .string(value)
    }

    typealias ArrayLiteralElement = String
    init(arrayLiteral elements: String...) {
      self = .array(elements)
    }
  }

  let data: String?
  let files: Dictionary<String, String>?
  let form: Dictionary<String, StringOrArray>?
  let headers: Dictionary<String, String>

  func headerValue(for key: String) -> String? {
    return headers.first(where: { $0.key.lowercased() == key.lowercased() })?.value
  }
}

final class CURLTests: XCTestCase {
  func test_performGet() async throws {
    var delegate = CURLClientGeneralDelegate()
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToGet()
    try await client.setURL(try XCTUnwrap(URL(string: "https://storage.googleapis.com/public.data.yockow.jp/test-assets/test.txt")))
    try await client.perform(delegate: &delegate)

    XCTAssertEqual(try XCTUnwrap(delegate.responseCode), 200)
    XCTAssertTrue(delegate.responseHeaderFields.contains(where: {
      $0.name.lowercased() == "content-length" && $0.value.contains("4")
    }))

    let responseString = delegate.responseBody(as: Data.self).flatMap {
      String(data: $0, encoding: .utf8)
    }
    XCTAssertEqual(responseString, "test")
  }

  func test_performHead() async throws {
    var delegate = CURLClientGeneralDelegate()
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToHead()
    try await client.setURL(try XCTUnwrap(URL(string: "https://storage.googleapis.com/public.data.yockow.jp/test-assets/test.txt")))
    try await client.perform(delegate: &delegate)

    XCTAssertEqual(try XCTUnwrap(delegate.responseCode), 200)
    XCTAssertEqual(delegate.responseBody(as: Data.self)?.count, 0)
  }

  func test_performPost() async throws {
    var delegate = CURLClientGeneralDelegate(requestBody: .init(data: Data("foo=foo&bar=bar".utf8)))
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/post")))
    try await client.perform(delegate: &delegate)

    let response = try delegate.responseBody(as: Data.self).map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    XCTAssertEqual(response?.form?["foo"], "foo")
    XCTAssertEqual(response?.form?["bar"], "bar")
  }

  func test_performPost_asyncRequestBody() async throws {
    struct __AsyncRequestBody: AsyncSequence {
      typealias Element = UInt8
      struct AsyncIterator: AsyncIteratorProtocol {
        typealias Element = UInt8
        var iterator: Data.Iterator
        mutating func next() async throws -> UInt8? { iterator.next() }
      }
      let data: Data
      func makeAsyncIterator() -> AsyncIterator { .init(iterator: data.makeIterator()) }
    }
    var delegate = CURLClientGeneralDelegate(
      requestBody: .init(__AsyncRequestBody(data: Data("async=async&test=test".utf8)))
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/post")))
    try await client.perform(delegate: &delegate)

    let response = try delegate.responseBody(as: Data.self).map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    XCTAssertEqual(response?.form?["async"], "async")
    XCTAssertEqual(response?.form?["test"], "test")
  }

  func test_performPost_multipartFormData() async throws {
    let boundary = "CURLTestsMultipartFormData"
    let multipartFormDataString = """
    --\(boundary)
    Content-Disposition: form-data; name="file"; filename="text.txt"
    Content-Type: text/plain

    MY TEXT.
    --\(boundary)
    Content-Disposition: form-data; name="name1"

    VALUE1
    --\(boundary)
    Content-Disposition: form-data; name="name2"

    VALUE2
    --\(boundary)--

    """.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline }).joined(separator: "\u{0D}\u{0A}")
    let requestBody = InputStream(data: Data(multipartFormDataString.utf8))
    requestBody.open()

    var delegate = CURLClientGeneralDelegate(
      requestHeaderFields: [
        (name: "Content-Type", value: "multipart/form-data; boundary=\(boundary)"),
      ],
      requestBody: .init(stream: requestBody)
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/post")))
    try await client.perform(delegate: &delegate)

    let response = try delegate.responseBody(as: Data.self).map {
      return try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    XCTAssertEqual(response?.files?["file"], "MY TEXT.")
    XCTAssertEqual(response?.form?["name1"], "VALUE1")
    XCTAssertEqual(response?.form?["name2"], "VALUE2")
  }

  func test_performPut() async throws {
    let text = "Hello, World!\n"
    var delegate = CURLClientGeneralDelegate(
      requestHeaderFields: [
        (name: "Content-Type", value: "text/plain"),
      ],
      requestBody: .init(data: Data(text.utf8))
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPut()
    try await client.setUploadFileSize(text.count)
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/put")))
    try await client.perform(delegate: &delegate)

    XCTAssertTrue(try XCTUnwrap(delegate.responseCode) / 100 == 2)
    let response = try delegate.responseBody(as: Data.self).map {
      return try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    XCTAssertEqual(response?.data, text)
  }

  func test_requestHeaders() async throws {
    var delegate = CURLClientGeneralDelegate(
      requestHeaderFields: [
        (name: "X-FOO", value: "FOO"),
        (name: "X-BAR", value: "BAR"),
      ]
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToGet()
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/get")))
    try await client.perform(delegate: &delegate)

    XCTAssertEqual(try XCTUnwrap(delegate.responseCode), 200)

    let response = try delegate.responseBody(as: Data.self).map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    XCTAssertEqual(response?.headerValue(for: "X-FOO"), "FOO")
    XCTAssertEqual(response?.headerValue(for: "X-BAR"), "BAR")
  }
}
