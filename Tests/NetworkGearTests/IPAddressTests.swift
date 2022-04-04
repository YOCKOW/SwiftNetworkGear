/***************************************************************************************************
 IPAddressTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import XCTest
@testable import NetworkGear

final class IPAddressTests: XCTestCase {
  func testIPAddress() {
    let v4String = "127.0.0.1"
    let v6String = "1234:5678:90AB:CDEF:1234:5678:90AB:CDEF"
    let v4MappedString = "::ffff:127.0.0.1"
    
    let v4 = IPAddress(string:v4String)
    XCTAssertNotNil(v4)
    XCTAssertEqual(v4!.description, v4String)
    
    let v6 = IPAddress(string:v6String)
    XCTAssertNotNil(v6)
    XCTAssertEqual(v6!.description.lowercased(), v6String.lowercased())
    
    let v4Mapped = IPAddress(string:v4MappedString)
    XCTAssertNotNil(v4Mapped)
    XCTAssertEqual(v4Mapped!.description.lowercased(), v4MappedString.lowercased())
    
    do {
      guard case .v4(let b0, let b1, let b2, let b3) = v4 else { XCTFail("Not IPv4."); return }
      XCTAssertEqual(b0, 127)
      XCTAssertEqual(b1, 0)
      XCTAssertEqual(b2, 0)
      XCTAssertEqual(b3, 1)
    }
    
    do {
      guard case .v6(let b0, let b1, let  b2, let  b3, let  b4, let  b5, let  b6, let  b7,
                     let b8, let b9, let b10, let b11, let b12, let b13, let b14, let b15) = v6 else { XCTFail("Not IPv6."); return }
      XCTAssertEqual(b0, 0x12)
      XCTAssertEqual(b1, 0x34)
      XCTAssertEqual(b2, 0x56)
      XCTAssertEqual(b3, 0x78)
      XCTAssertEqual(b4, 0x90)
      XCTAssertEqual(b5, 0xAB)
      XCTAssertEqual(b6, 0xCD)
      XCTAssertEqual(b7, 0xEF)
      XCTAssertEqual(b8, 0x12)
      XCTAssertEqual(b9, 0x34)
      XCTAssertEqual(b10, 0x56)
      XCTAssertEqual(b11, 0x78)
      XCTAssertEqual(b12, 0x90)
      XCTAssertEqual(b13, 0xAB)
      XCTAssertEqual(b14, 0xCD)
      XCTAssertEqual(b15, 0xEF)
    }
    
    XCTAssertEqual(v4!, v4Mapped!)
  }
}
