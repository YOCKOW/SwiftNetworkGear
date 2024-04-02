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
    try await client.setURL(try XCTUnwrap(URL(string: "https://example.com/")))
    try await client.perform()

    let responseString = await client.responseBody.flatMap({ String(data: $0, encoding: .utf8) })
    XCTAssertTrue(try XCTUnwrap(responseString).lowercased().contains("example"))
  }
}
