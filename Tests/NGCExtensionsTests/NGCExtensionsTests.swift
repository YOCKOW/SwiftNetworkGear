/***************************************************************************************************
 NGCExtensionsTests.swift
   © 2018, 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import XCTest
@testable import _NGCExtensions

final class NGCExtensionsTests: XCTestCase {
  func testCIPAddress() {
    let v4_1 = CIPv4Address((127,0,0,1))
    let v4_2 = CIPv4Address([127,0,0,1])!
    let v4_3 = CIPv4Address("127.0.0.1")!
    
    XCTAssertEqual(v4_1, v4_2)
    XCTAssertEqual(v4_1, v4_3)
    
    let v6_1 = CIPv6Address((0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF,0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF))
    let v6_2 = CIPv6Address([0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF,0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF])!
    let v6_3 = CIPv6Address("1234:5678:90AB:CDEF:1234:5678:90AB:CDEF")!
    
    XCTAssertEqual(v6_1, v6_2)
    XCTAssertEqual(v6_1, v6_3)
  }
  
  func testCUNIXSocketAddress() {
    let path = "/tmp/swift-network-tests.sock"
    
    var u_1 = sockaddr_un()
    let pathMaxSize = MemoryLayout.size(ofValue:u_1.sun_path)
    withUnsafeMutablePointer(to:&u_1.sun_path) {
      $0.withMemoryRebound(to:CChar.self, capacity:pathMaxSize) {
        let _ = strncpy($0, path, pathMaxSize)
      }
    }
    
    let u_2 = CUNIXSocketAddress(path:path)!
    
    XCTAssertEqual(u_1.path, u_2.path)
  }
}
