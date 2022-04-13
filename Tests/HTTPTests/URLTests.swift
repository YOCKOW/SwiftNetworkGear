/* *************************************************************************************************
 URLTests.swift
   © 2019, 2022 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import NetworkGear
import Foundation

final class URLTests: XCTestCase {
  @available(macOS 12.0, *)
  func test_content() async throws {
    let string = "テスト文字列"
    let url = try XCTUnwrap(URL(internationalString: "https://Bot.YOCKOW.jp/-/stringContent/\(string)"))
    let maybeContent = try await url.finalContent
    let content = try XCTUnwrap(maybeContent)
    XCTAssertEqual(String(data: content, encoding: .utf8), string)
  }

  @available(macOS 12.0, *)
  func test_redirectedContent() async throws {
    let url = try XCTUnwrap(URL(string: "http://YOCKOW.net/"))
    let maybeContent = try await url.finalContent
    let content = try XCTUnwrap(maybeContent)
    let contentString = try XCTUnwrap(String(data: content, encoding: .utf8))
    XCTAssertTrue(contentString.contains("Where YOCKOW does something:"))
  }
  
  func test_postRequest() {
    // TODO: Add tests.
  }
  
  @available(macOS 12.0, *)
  func test_lastModified() async throws {
    let time = floor(Date().timeIntervalSinceReferenceDate - 86400.0)
    let date = Date(timeIntervalSinceReferenceDate: time)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMddHHmmss"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let url = URL(string: "https://Bot.YOCKOW.jp/-/lastModified/\(formatter.string(from: date))")
    let lastModified = try await url?.lastModifiedDate
    XCTAssertEqual(lastModified, date)
  }
  
  @available(macOS 12.0, *)
  func test_eTag() async throws {
    let eTagString = "myETag"
    let eTag = HTTPETag.weak(eTagString)
    
    let url = URL(string: "https://Bot.YOCKOW.jp/-/eTag/weak:\(eTagString)")
    let actualETag = try await url?.httpETag
    XCTAssertEqual(actualETag, eTag)
  }
}

