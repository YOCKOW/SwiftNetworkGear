/***************************************************************************************************
 DomainTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import XCTest
@testable import Network

final class DomainTests: XCTestCase {
  func testInitialization() {
    let tests: [(String, String, Domain.Label.ValidityOptions)] = [
      ("YOCKOW.jp", "yockow.jp", .default),
      ("日本。ＪＰ", "xn--wgv71a.jp", .default),
      ("EXAMPLE.COM.", "example.com.", .idna2008),
      ("9999999999999999999999.NET", "9999999999999999999999.net", [])
    ]
    
    for test in tests {
      let domain = Domain(test.0, options:test.2)
      XCTAssertNotNil(domain)
      XCTAssertEqual(domain!.description, test.1)
    }
  }
  
  static var allTests = [
    ("testInitialization", testInitialization),
  ]
}

