/***************************************************************************************************
 CNetworkGearTests.swift
   © 2018,2022,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import XCTest
import CNetworkGear
@testable import NetworkGear
import sockaddr_tests

final class CNetworkGearTests: XCTestCase {
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

  func testSocketAddress() throws {
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
    let control_in = SocketAddress(socketAddress: CIPv4SocketAddress(ipAddress: CIPv4Address("127.0.0.1")!, port: 12345))
    let _in = _sat_in()
    let in4 = SocketAddress(_in!)
    XCTAssertTrue(in4.cSocketAddress is CIPv4SocketAddress)
    XCTAssertEqual(control_in.size, in4.size)
    XCTAssertEqual(control_in.family, in4.family)
    let control_ipv4sockaddr = try XCTUnwrap(control_in.cSocketAddress as? CIPv4SocketAddress)
    let ipv4sockaddr = try XCTUnwrap(in4.cSocketAddress as? CIPv4SocketAddress)
    XCTAssertEqual(control_ipv4sockaddr.port, ipv4sockaddr.port)
    XCTAssertEqual(control_ipv4sockaddr.ipAddress.description, ipv4sockaddr.ipAddress.description)
    _sat_free(_in)

    // sockaddr_in6
    let control_in6 = SocketAddress(socketAddress:CIPv6SocketAddress(ipAddress:CIPv6Address("1234:5678:90AB:CDEF:1234:5678:90AB:CDEF")!, port:12345))
    let _in6 = _sat_in6()
    let in6 = SocketAddress(_in6!)
    XCTAssertTrue(in6.cSocketAddress is CIPv6SocketAddress)
    XCTAssertEqual(control_in6.size, in6.size)
    XCTAssertEqual(control_in6.family, in6.family)
    let control_ipv6sockaddr = try XCTUnwrap(control_in6.cSocketAddress as? CIPv6SocketAddress)
    let ipv6sockaddr = try XCTUnwrap(in6.cSocketAddress as? CIPv6SocketAddress)
    XCTAssertEqual(control_ipv6sockaddr.port, ipv6sockaddr.port)
    XCTAssertEqual(control_ipv6sockaddr.flowIdentifier, ipv6sockaddr.flowIdentifier)
    XCTAssertEqual(control_ipv6sockaddr.scopeIdentifier, ipv6sockaddr.scopeIdentifier)
    let control_ipv6 = control_ipv6sockaddr.ipAddress
    let ipv6 = ipv6sockaddr.ipAddress
    XCTAssertEqual(control_ipv6.description, ipv6.description)
    _sat_free(_in6)
  }
}
