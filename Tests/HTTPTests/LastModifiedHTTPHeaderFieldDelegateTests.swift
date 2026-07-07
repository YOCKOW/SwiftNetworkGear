/* *************************************************************************************************
 LastModifiedHTTPHeaderFieldDelegateTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Foundation
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
