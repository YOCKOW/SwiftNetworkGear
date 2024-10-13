/* *************************************************************************************************
 ContentDispositionTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite struct ContentDispositionTests {
  @Test func test_parser() {
    let attachment = ContentDisposition("attachment; filename=\"myfile.txt\"")
    #expect(attachment.value == .attachment)
    #expect(attachment.parameters?["filename"] == "myfile.txt")


    let formData = ContentDisposition("form-data; name=\"field\"")
    #expect(formData.value == .formData)
    #expect(formData.parameters?["name"] == "field")
  }
}
#else
import XCTest

final class ContentDispositionTests: XCTestCase {
  func test_parser() {
    let attachment = ContentDisposition("attachment; filename=\"myfile.txt\"")
    XCTAssertEqual(attachment.value, .attachment)
    XCTAssertEqual(attachment.parameters?["filename"], "myfile.txt")
    
    
    let formData = ContentDisposition("form-data; name=\"field\"")
    XCTAssertEqual(formData.value, .formData)
    XCTAssertEqual(formData.parameters?["name"], "field")
  }
}
#endif
