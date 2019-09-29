/* *************************************************************************************************
 LastModifiedHeaderFieldDelegateTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import HTTP

import Foundation

final class LastModifiedHeaderFieldDelegateTests: XCTestCase {
  func test_value() {
    let dateString = "Mon, 03 Oct 1983 16:21:09 GMT"
    let dateFieldValue = HeaderFieldValue(rawValue: dateString)!
    let date = Date(headerFieldValue: dateFieldValue)!
    let lastModified = HeaderField(name:.lastModified, value: dateFieldValue)
    
    XCTAssertEqual(lastModified.source as? Date, date)
    XCTAssertEqual(lastModified.value.rawValue, dateString)
    
    let lastModified2 = HeaderField.lastModified(date)
    XCTAssertEqual(lastModified.source as? Date, lastModified2.source as? Date)
  }
}






