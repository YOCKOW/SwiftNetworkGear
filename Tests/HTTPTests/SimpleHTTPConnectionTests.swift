/* *************************************************************************************************
 SimpleHTTPConnectionTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import NetworkGear


final class SimpleHTTPConnectionTests: XCTestCase {
  func test_simpleGet() async throws {
    let url = try XCTUnwrap(URL(string: "https://storage.googleapis.com/public.data.yockow.jp/test-assets/test.txt"))
    let connection = SimpleHTTPConnection(url: url)
    let response = try await connection.response()
    XCTAssertEqual(response.statusCode, .ok)
    XCTAssertTrue(response.header.contains(where: { $0.name == .contentType && $0.value.rawValue == "text/plain" }))
    XCTAssertEqual(response.content.flatMap({ String(data: $0, encoding: .utf8) }), "test")
  }
}
