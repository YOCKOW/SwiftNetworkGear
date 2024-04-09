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

  let form: Dictionary<String, StringOrArray>?
  let headers: Dictionary<String, String>

  func headerValue(for key: String) -> String? {
    return headers.first(where: { $0.key.lowercased() == key.lowercased() })?.value
  }
}

final class CURLTests: XCTestCase {
  func test_performGet() async throws {
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToGet()
    try await client.setURL(try XCTUnwrap(URL(string: "https://storage.googleapis.com/public.data.yockow.jp/test-assets/test.txt")))
    try await client.perform()

    let responseCode = await client.responseCode
    XCTAssertTrue(try XCTUnwrap(responseCode) / 100 == 2)

    let responseHeaders = await client.responseHeaders
    XCTAssertTrue(try XCTUnwrap(responseHeaders).contains(where: {
      $0.name.lowercased() == "content-length" && $0.value.contains("4")
    }))

    let responseString = await client.responseBody.flatMap({ String(data: $0, encoding: .utf8) })
    XCTAssertEqual(responseString, "test")
  }

  func test_performPost() async throws {
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/post")))

    let requestBodyString = "foo=foo&bar=bar"
    let requestBodyData = Data(requestBodyString.utf8)
    var requestBody = CURLRequestBodyByteSequence(requestBodyData)
    try await client.perform(requestBody: &requestBody)

    let response = try await client.responseBody.map {
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

    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/post")))

    let requestBodyString = "async=async&test=test"
    var requestBody = CURLRequestBodyByteSequence(
      __AsyncRequestBody(data: Data(requestBodyString.utf8))
    )
    try await client.perform(requestBody: &requestBody)

    let response = try await client.responseBody.map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    XCTAssertEqual(response?.form?["async"], "async")
    XCTAssertEqual(response?.form?["test"], "test")
  }

  func test_requestHeaders() async throws {
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToGet()
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/get")))
    await client.setRequestHeaders([
      (name: "X-FOO", value: "FOO"),
      (name: "X-BAR", value: "BAR"),
    ])
    try await client.perform()

    let responseCode = await client.responseCode
    XCTAssertTrue(try XCTUnwrap(responseCode) / 100 == 2)

    let response = try await client.responseBody.map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    XCTAssertEqual(response?.headerValue(for: "X-FOO"), "FOO")
    XCTAssertEqual(response?.headerValue(for: "X-BAR"), "BAR")
  }
}
