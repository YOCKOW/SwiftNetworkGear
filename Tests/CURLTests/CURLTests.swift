/* *************************************************************************************************
 CURLTests.swift
   © 2024-2025 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import _NetworkGearTestSupport
import CLibCURL
@testable import CURLClient
import Foundation
import Testing

@Suite struct CURLTests {
  @Test func test_defaultUserAgent() {
    #expect(EasyClient.defaultUserAgent.hasPrefix("SwiftNetworkGearClient/"))
  }

  @Test func test_performDelete() async throws {
    let delegate = CURLClientGeneralDelegate()
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToCustom("DELETE")
    try await client.setURL(try #require(URL(string: "https://httpcan.org/delete")))
    try await client.perform(delegate: delegate)

    #expect(try #require(delegate.responseCode) == 200)
  }

  @Test func test_performGet() async throws {
    let delegate = CURLClientGeneralDelegate()
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToGet()
    try await client.setURL(try #require(URL(string: "https://storage.googleapis.com/public.data.yockow.jp/test-assets/test.txt")))
    try await client.perform(delegate: delegate)

    #expect(delegate.didFinish)
    #expect(try #require(delegate.responseCode) == 200)
    #expect(delegate.responseHeaderFields.contains(where: {
      $0.name.lowercased() == "content-length" && $0.value.contains("4")
    }))

    let responseString = delegate.responseBody(as: Data.self).flatMap {
      String(data: $0, encoding: .utf8)
    }
    #expect(responseString == "test")
  }

  @Test func test_performHead() async throws {
    let delegate = CURLClientGeneralDelegate()
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToHead()
    try await client.setURL(try #require(URL(string: "https://storage.googleapis.com/public.data.yockow.jp/test-assets/test.txt")))
    try await client.perform(delegate: delegate)

    #expect(try #require(delegate.responseCode) == 200)
    #expect(delegate.responseBody(as: Data.self)?.count == 0)
  }

  @Test func test_performPost() async throws {
    let delegate = CURLClientGeneralDelegate(requestBody: .init(data: Data("foo=foo&bar=bar".utf8)))
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try #require(URL(string: "https://httpcan.org/post")))
    try await client.perform(delegate: delegate)

    let response = try delegate.responseBody(as: Data.self).map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    #expect(response?.form?["foo"] == "foo")
    #expect(response?.form?["bar"] == "bar")
  }

  @Test func test_performPostRedirection() async throws {
    let delegate = CURLClientGeneralDelegate(
      requestHeaderFields: [
        (name: "X-Y-POST-Redirection", value: "yes"),
      ],
      requestBody: .init(data: Data("redirected=yes".utf8))
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try #require(URL(string: "https://httpcan.org/redirect-to?url=%2Fpost&status_code=308")))
    try await client.setMaxNumberOfRedirectsAllowed(30)
    try await client.perform(delegate: delegate)

    let response = try delegate.responseBody(as: Data.self).map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    #expect(response?.form?["redirected"] == "yes")
  }

  @Test func test_performPost_asyncRequestBody() async throws {
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
    let delegate = CURLClientGeneralDelegate(
      requestBody: .init(__AsyncRequestBody(data: Data("async=async&test=test".utf8)))
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try #require(URL(string: "https://httpcan.org/post")))
    try await client.perform(delegate: delegate)

    let response = try delegate.responseBody(as: Data.self).map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    #expect(response?.form?["async"] == "async")
    #expect(response?.form?["test"] == "test")
  }

  @Test func test_performPost_multipartFormData() async throws {
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

    let delegate = CURLClientGeneralDelegate(
      requestHeaderFields: [
        (name: "Content-Type", value: "multipart/form-data; boundary=\(boundary)"),
      ],
      requestBody: .init(stream: requestBody)
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPost()
    try await client.setURL(try #require(URL(string: "https://httpcan.org/post")))
    try await client.perform(delegate: delegate)

    let response = try delegate.responseBody(as: Data.self).map {
      return try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    #expect(response?.files?["file"] == "MY TEXT.")
    #expect(response?.form?["name1"] == "VALUE1")
    #expect(response?.form?["name2"] == "VALUE2")
  }

  @Test func test_performPut() async throws {
    let text = "Hello, World!\n"
    let delegate = CURLClientGeneralDelegate(
      requestHeaderFields: [
        (name: "Content-Type", value: "text/plain"),
      ],
      requestBody: .init(data: Data(text.utf8))
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToPut()
    try await client.setUploadFileSize(text.count)
    try await client.setURL(try #require(URL(string: "https://httpcan.org/put")))
    try await client.perform(delegate: delegate)

    #expect(try #require(delegate.responseCode) / 100 == 2)
    let response = try delegate.responseBody(as: Data.self).map {
      return try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    #expect(response?.data == text)
  }

  @Test func test_requestHeaders() async throws {
    let delegate = CURLClientGeneralDelegate(
      requestHeaderFields: [
        (name: "X-FOO", value: "FOO"),
        (name: "X-BAR", value: "BAR"),
      ]
    )
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToGet()
    try await client.setURL(try #require(URL(string: "https://httpcan.org/get")))
    try await client.perform(delegate: delegate)

    #expect(try #require(delegate.responseCode) == 200)

    let response = try delegate.responseBody(as: Data.self).map {
      try JSONDecoder().decode(HTTPBinResponse.self, from: $0)
    }
    #expect(response?.headerValue(for: "X-FOO") == "FOO")
    #expect(response?.headerValue(for: "X-BAR") == "BAR")
  }

  @Test func test_simultaneousHTTPRequestsWithoutCURLMultiInterface() async throws {
    let urls: [String] = [
      "https://www.Apple.com/",
      "https://cURL.se/",
      "https://www.Example.com/",
      "https://www.Google.co.jp/",
      "https://httpcan.org/",
      "https://www.Swift.org/",
      "https://www.Wikipedia.org/",
      "https://www.Yahoo.co.jp/",
      "https://Bot.YOCKOW.jp/",
      "https://Choeropsis-liberiensis.YOCKOW.jp/",
    ]

    func __clientFromURL(_ url: String) async throws -> EasyClient {
      let client = try CURLManager.shared.makeEasyClient()
      try await client.setHTTPMethodToGet()
      try await client.setURL(try #require(URL(string: url)))
      return client
    }

    let results = try await withThrowingTaskGroup(of: (String, CURLResponseCode).self) { group in
      var urlsAndClients: [(String, EasyClient)] = []
      for url in urls {
        urlsAndClients.append((url, try await __clientFromURL(url)))
      }
      for urlAndClient in urlsAndClients {
        group.addTask {
          let delegate = CURLClientGeneralDelegate()
          try await urlAndClient.1.perform(delegate: delegate)
          return (urlAndClient.0, delegate.responseCode)
        }
      }
      return try await group.reduce(into: []) { $0.append($1) }
    }
    for result in results {
      let codeDivBy100 = result.1 / 100
      #expect(
        codeDivBy100 == 2 || codeDivBy100 == 3,
        "Unexpected response code \(result.1) for URL \(result.0)"
      )
    }
  }

  @Test func test_adhocErrorHandling_HTTP2Head() async throws {
    let delegate = CURLClientGeneralDelegate()
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setHTTPMethodToHead()
    try await client.setURL(try #require(URL(string: "https://bot.yockow.jp/-/eTag/weak:foo")))
    try await client.perform(delegate: delegate)

    #expect(try #require(delegate.responseCode) == 200)
    #expect(delegate.responseBody(as: Data.self)?.count == 0)
  }
}
