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
  func test_postRequest() {
    // TODO: Add tests.
  }
  
  func test_lastModified() {
    // FIXME: Use internal server.
    let url = URL(string: "https://example.com/")!
    let past = Date(timeIntervalSince1970: 0.0)
    let future = Date(timeIntervalSinceNow: 157680000.0)
    
    let lastModified = url.lastModified
    XCTAssertNotNil(lastModified)
    XCTAssertGreaterThan(lastModified!, past)
    XCTAssertLessThan(lastModified!, future)
  }
  
  func test_eTag() {
    // TODO: Add tests.
  }
}

