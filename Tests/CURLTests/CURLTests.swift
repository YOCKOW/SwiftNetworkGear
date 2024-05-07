/* *************************************************************************************************
 CURLTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
import _NetworkGearTestSupport
import CLibCURL
@testable import CURLClient

final class CURLTests: XCTestCase {
  func test_defaultUserAgent() {
    XCTAssertTrue(EasyClient.defaultUserAgent.hasPrefix("SwiftNetworkGearClient/"))
  }

  func test_performDelete() async throws {
    var delegate = CURLClientGeneralDelegate()
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToCustom("DELETE")
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/delete")))
    try await client.perform(delegate: &delegate)

    XCTAssertEqual(try XCTUnwrap(delegate.responseCode), 200)
  }

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

  func test_performPostRedirection() async throws {
    var delegate = CURLClientGeneralDelegate(
      requestHeaderFields: [
        (name: "X-Y-POST-Redirection", value: "yes"),
      ],
      requestBody: .init(data: Data("redirected=yes".utf8))
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try XCTUnwrap(URL(string: "https://httpbin.org/redirect-to?url=%2Fpost&status_code=308")))
    try await client.setMaxNumberOfRedirectsAllowed(30)
    try await client.perform(delegate: &delegate)

    let response = try delegate.responseBody(as: Data.self).map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    XCTAssertEqual(response?.form?["redirected"], "yes")
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

  func test_simultaneousHTTPRequestsWithoutCURLMultiInterface() async throws {
    let urls: [String] = [
      "https://www.Apple.com/",
      "https://cURL.se/",
      "https://www.Example.com/",
      "https://www.Google.co.jp/",
      "https://httpbin.org/",
      "https://www.Swift.org/",
      "https://www.Wikipedia.org/",
      "https://www.Yahoo.co.jp/",
      "https://Bot.YOCKOW.jp/",
      "https://Choeropsis-liberiensis.YOCKOW.jp/",
    ]

    func __clientFromURL(_ url: String) async throws -> EasyClient {
      let client = try CURLManager.shared.makeEasyClient()
      try await client.setHTTPMethodToGet()
      try await client.setURL(try XCTUnwrap(URL(string: url)))
      return client
    }

    let results = try await withThrowingTaskGroup(of: (String, CURLResponseCode).self) { group in
      var urlsAndClients: [(String, EasyClient)] = []
      for url in urls {
        urlsAndClients.append((url, try await __clientFromURL(url)))
      }
      for urlAndClient in urlsAndClients {
        group.addTask {
          var delegate = CURLClientGeneralDelegate()
          try await urlAndClient.1.perform(delegate: &delegate)
          return (urlAndClient.0, delegate.responseCode)
        }
      }
      return try await group.reduce(into: []) { $0.append($1) }
    }
    for result in results {
      let codeDivBy100 = result.1 / 100
      XCTAssertTrue(
        codeDivBy100 == 2 || codeDivBy100 == 3,
        "Unexpected response code \(result.1) for URL \(result.0)"
      )
    }
  }

  func test_adhocErrorHandling_HTTP2Head() async throws {
    var delegate = CURLClientGeneralDelegate()
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToHead()
    try await client.setURL(try XCTUnwrap(URL(string: "https://bot.yockow.jp/-/eTag/weak:foo")))
    try await client.perform(delegate: &delegate)

    XCTAssertEqual(try XCTUnwrap(delegate.responseCode), 200)
    XCTAssertEqual(delegate.responseBody(as: Data.self)?.count, 0)
  }
}
