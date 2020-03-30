/***************************************************************************************************
 CTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import XCTest
@testable import NetworkGear

import sockaddr_tests

final class CTests: XCTestCase {
  func testCIPAddress() {
    let v4_1 = CIPv4Address((127,0,0,1))
    let v4_2 = CIPv4Address([127,0,0,1])!
    let v4_3 = CIPv4Address(string:"127.0.0.1")!
    
    XCTAssertEqual(v4_1.bytes, v4_2.bytes)
    XCTAssertEqual(v4_1.bytes, v4_3.bytes)
    
    let v6_1 = CIPv6Address((0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF,0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF))
    let v6_2 = CIPv6Address([0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF,0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF])!
    let v6_3 = CIPv6Address(string:"1234:5678:90AB:CDEF:1234:5678:90AB:CDEF")!
    
    XCTAssertEqual(v6_1.bytes, v6_2.bytes)
    XCTAssertEqual(v6_1.bytes, v6_3.bytes)
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
  
  func testSocketAddress() {
    // sockaddr_un
    let control_un = SocketAddress(socketAddress:CUNIXSocketAddress(path:"test")!)
    let _un = _sat_un()
    let un = SocketAddress(_un!)
    XCTAssertTrue(un.cSocketAddress is CUNIXSocketAddress)
    XCTAssertEqual(control_un.size, un.size)
    XCTAssertEqual(control_un.family, un.family)
    XCTAssertEqual((control_un.cSocketAddress as! CUNIXSocketAddress).path, (un.cSocketAddress as! CUNIXSocketAddress).path)
    _sat_free(_un)
    
    // sockaddr_in
    let control_in = SocketAddress(socketAddress:CIPv4SocketAddress(ipAddress:CIPv4Address(string:"127.0.0.1")!, port:12345)!)
    let _in = _sat_in()
    let in4 = SocketAddress(_in!)
    XCTAssertTrue(in4.cSocketAddress is CIPv4SocketAddress)
    XCTAssertEqual(control_in.size, in4.size)
    XCTAssertEqual(control_in.family, in4.family)
    let control_ipv4sockaddr = control_in.cSocketAddress as! CIPSocketAddress
    let ipv4sockaddr = in4.cSocketAddress as! CIPSocketAddress
    XCTAssertEqual(control_ipv4sockaddr.port, ipv4sockaddr.port)
    XCTAssertEqual(control_ipv4sockaddr.ipAddress.description, ipv4sockaddr.ipAddress.description)
    _sat_free(_in)
 
    // sockaddr_in6
    let control_in6 = SocketAddress(socketAddress:CIPv6SocketAddress(ipAddress:CIPv6Address(string:"1234:5678:90AB:CDEF:1234:5678:90AB:CDEF")!, port:12345)!)
    let _in6 = _sat_in6()
    let in6 = SocketAddress(_in6!)
    XCTAssertTrue(in6.cSocketAddress is CIPv6SocketAddress)
    XCTAssertEqual(control_in6.size, in6.size)
    XCTAssertEqual(control_in6.family, in6.family)
    let control_ipv6sockaddr = control_in6.cSocketAddress as! CIPv6SocketAddress
    let ipv6sockaddr = in6.cSocketAddress as! CIPv6SocketAddress
    XCTAssertEqual(control_ipv6sockaddr.port, ipv6sockaddr.port)
    XCTAssertEqual(control_ipv6sockaddr.flowIdentifier, ipv6sockaddr.flowIdentifier)
    XCTAssertEqual(control_ipv6sockaddr.scopeIdentifier, ipv6sockaddr.scopeIdentifier)
    let control_ipv6 = control_ipv6sockaddr.ipAddress as! CIPv6Address
    let ipv6 = ipv6sockaddr.ipAddress as! CIPv6Address
    XCTAssertEqual(control_ipv6.description, ipv6.description)
    _sat_free(_in6)
  }
  
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
  
  static var allTests = [
    ("testCIPAddress", testCIPAddress),
    ("testCUNIXSocketAddress", testCUNIXSocketAddress),
    ("testSocketAddress", testSocketAddress),
    ("testIPAddress", testIPAddress),
  ]
}
