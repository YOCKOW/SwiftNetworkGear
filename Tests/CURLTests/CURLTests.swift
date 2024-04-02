/* *************************************************************************************************
 CURLTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import CURLClient

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
}
