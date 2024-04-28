/* *************************************************************************************************
 SimpleHTTPConnectionTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
import CLibCURL
import CURLClient
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

  func test_redirects() async throws {
    let url = try XCTUnwrap(URL(string: "https://httpbin.org/absolute-redirect/4"))

    // No redirect
    let connection1 = SimpleHTTPConnection(url: url, redirectStrategy: .noFollow)
    let response1 = try await connection1.response()
    XCTAssertEqual(response1.statusCode, .found)

    // Few redirects
    let connection2 = SimpleHTTPConnection(url: url, redirectStrategy: .followRedirects(maxCount: 2))
    do {
      let _ = try await connection2.response()
    } catch CURLClientError.curlCode(let curlCode) {
      XCTAssertEqual(curlCode, CURLE_TOO_MANY_REDIRECTS)
    } catch {
      XCTFail("Unexpected error: \(error.localizedDescription)")
    }

    // Enough redirects
    let connection3 = SimpleHTTPConnection(url: url, redirectStrategy: .followRedirects(maxCount: 10))
    let response3 = try await connection3.response()
    XCTAssertEqual(response3.statusCode, .ok)
  }
}
