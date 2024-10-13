/* *************************************************************************************************
 LastModifiedHTTPHeaderFieldDelegateTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

import Foundation

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class LastModifiedHTTPHeaderFieldDelegateTests {
  @Test func test_value() {
    let dateString = "Mon, 03 Oct 1983 16:21:09 GMT"
    let dateFieldValue = HTTPHeaderFieldValue(rawValue: dateString)!
    let date = Date(dateFieldValue)!
    let lastModified = HTTPHeaderField(name:.lastModified, value: dateFieldValue)

    #expect(lastModified.source as? Date == date)
    #expect(lastModified.value.rawValue == dateString)

    let lastModified2 = HTTPHeaderField.lastModified(date)
    #expect(lastModified.source as? Date == lastModified2.source as? Date)
  }
}
#else
import XCTest

final class LastModifiedHTTPHeaderFieldDelegateTests: XCTestCase {
  func test_value() {
    let dateString = "Mon, 03 Oct 1983 16:21:09 GMT"
    let dateFieldValue = HTTPHeaderFieldValue(rawValue: dateString)!
    let date = Date(dateFieldValue)!
    let lastModified = HTTPHeaderField(name:.lastModified, value: dateFieldValue)
    
    XCTAssertEqual(lastModified.source as? Date, date)
    XCTAssertEqual(lastModified.value.rawValue, dateString)
    
    let lastModified2 = HTTPHeaderField.lastModified(date)
    XCTAssertEqual(lastModified.source as? Date, lastModified2.source as? Date)
  }
}
#endif
