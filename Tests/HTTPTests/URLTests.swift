/* *************************************************************************************************
 URLTests.swift
   © 2019,2022,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Foundation

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class URLTests {
  @Test func test_content() async throws {
    let string = "テスト文字列"
    let url = try #require(URL(internationalString: "https://Bot.YOCKOW.jp/-/stringContent/\(string)"))
    var maybeContent: Data? = nil
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
      maybeContent = try await url.finalContent
    } else {
      maybeContent = url.content
    }
    let content = try #require(maybeContent)
    #expect(String(data: content, encoding: .utf8) == string)
  }

  @Test func test_redirectedContent() async throws {
    guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) else {
      return
    }
    let url = try #require(URL(string: "http://YOCKOW.net/"))
    let maybeContent = try await url.finalContent
    let content = try #require(maybeContent)
    let contentString = try #require(String(data: content, encoding: .utf8))
    #expect(contentString.contains("Where YOCKOW does something:"))
  }

  @Test func test_postRequest() {
    // TODO: Add tests.
  }

  @Test func test_lastModified() async throws {
    let time = floor(Date().timeIntervalSinceReferenceDate - 86400.0)
    let date = Date(timeIntervalSinceReferenceDate: time)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMddHHmmss"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    let url = try #require(
      URL(string: "https://Bot.YOCKOW.jp/-/lastModified/\(formatter.string(from: date))")
    )
    var lastModified: Date? = nil
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
      lastModified = try await url.lastModifiedDate
    } else {
      lastModified = url.lastModified
    }
    #expect(lastModified == date)
  }

  @Test func test_eTag() async throws {
    let eTagString = "myETag"
    let eTag = HTTPETag.weak(eTagString)

    let url = try #require(URL(string: "https://Bot.YOCKOW.jp/-/eTag/weak:\(eTagString)"))
    var actualETag: HTTPETag? = nil
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
      actualETag = try await url.httpETag
    } else {
      actualETag = url.eTag
    }
    #expect(actualETag == eTag)
  }
}
#else
import XCTest

final class URLTests: XCTestCase {
  func test_content() async throws {
    let string = "テスト文字列"
    let url = try XCTUnwrap(URL(internationalString: "https://Bot.YOCKOW.jp/-/stringContent/\(string)"))
    var maybeContent: Data? = nil
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
      maybeContent = try await url.finalContent
    } else {
      maybeContent = url.content
    }
    let content = try XCTUnwrap(maybeContent)
    XCTAssertEqual(String(data: content, encoding: .utf8), string)
  }

  func test_redirectedContent() async throws {
    guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) else {
      return
    }
    let url = try XCTUnwrap(URL(string: "http://YOCKOW.net/"))
    let maybeContent = try await url.finalContent
    let content = try XCTUnwrap(maybeContent)
    let contentString = try XCTUnwrap(String(data: content, encoding: .utf8))
    XCTAssertTrue(contentString.contains("Where YOCKOW does something:"))
  }
  
  func test_postRequest() {
    // TODO: Add tests.
  }

  func test_lastModified() async throws {
    let time = floor(Date().timeIntervalSinceReferenceDate - 86400.0)
    let date = Date(timeIntervalSinceReferenceDate: time)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMddHHmmss"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let url = try XCTUnwrap(
      URL(string: "https://Bot.YOCKOW.jp/-/lastModified/\(formatter.string(from: date))")
    )
    var lastModified: Date? = nil
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
      lastModified = try await url.lastModifiedDate
    } else {
      lastModified = url.lastModified
    }
    XCTAssertEqual(lastModified, date)
  }

  func test_eTag() async throws {
    let eTagString = "myETag"
    let eTag = HTTPETag.weak(eTagString)
    
    let url = try XCTUnwrap(URL(string: "https://Bot.YOCKOW.jp/-/eTag/weak:\(eTagString)"))
    var actualETag: HTTPETag? = nil
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
      actualETag = try await url.httpETag
    } else {
      actualETag = url.eTag
    }
    XCTAssertEqual(actualETag, eTag)
  }
}
#endif
