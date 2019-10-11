/* *************************************************************************************************
 URLTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import HTTP
import Foundation

final class URLTests: XCTestCase {
  func test_content() throws {
    let string = "テスト文字列"
    let url = try XCTUnwrap(URL(internationalString: "https://Bot.YOCKOW.jp/-/stringContent/\(string)"))
    let content = try XCTUnwrap(url.content)
    XCTAssertEqual(String(data: content, encoding: .utf8), string)
  }
  
  func test_postRequest() {
    // TODO: Add tests.
  }
  
  func test_lastModified() {
    let time = floor(Date().timeIntervalSinceReferenceDate - 86400.0)
    let date = Date(timeIntervalSinceReferenceDate: time)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMddHHmmss"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let url = URL(string: "https://Bot.YOCKOW.jp/-/lastModified/\(formatter.string(from: date))")
    XCTAssertEqual(url?.lastModified, date)
  }
  
  func test_eTag() {
    let eTagString = "myETag"
    let eTag = ETag.weak(eTagString)
    
    let url = URL(string: "https://Bot.YOCKOW.jp/-/eTag/weak:\(eTagString)")
    XCTAssertEqual(url?.eTag, eTag)
  }
}

