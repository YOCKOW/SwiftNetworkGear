/* *************************************************************************************************
 LastModifiedHTTPHeaderFieldDelegateTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import NetworkGear

import Foundation

final class LastModifiedHTTPHeaderFieldDelegateTests: XCTestCase {
  func test_value() {
    let dateString = "Mon, 03 Oct 1983 16:21:09 GMT"
    let dateFieldValue = HTTPHeaderFieldValue(rawValue: dateString)!
    let date = Date(headerFieldValue: dateFieldValue)!
    let lastModified = HTTPHeaderField(name:.lastModified, value: dateFieldValue)
    
    XCTAssertEqual(lastModified.source as? Date, date)
    XCTAssertEqual(lastModified.value.rawValue, dateString)
    
    let lastModified2 = HTTPHeaderField.lastModified(date)
    XCTAssertEqual(lastModified.source as? Date, lastModified2.source as? Date)
  }
}






