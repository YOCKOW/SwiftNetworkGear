/* *************************************************************************************************
 CURLTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import CURLClient

struct HTTPBinResponse: Decodable {
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
