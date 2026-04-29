/***************************************************************************************************
 IPAddressTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

@testable import NetworkGear
import Testing

@Suite final class IPAddressTests {
  @Test func testIPAddress() throws {
    let v4String = "127.0.0.1"
    let v6String = "1234:5678:90AB:CDEF:1234:5678:90AB:CDEF"
    let v4MappedString = "::ffff:127.0.0.1"

    let v4 = try #require(IPAddress(string: v4String))
    #expect(v4.description == v4String)

    let v6 = try #require(IPAddress(string: v6String))
    #expect(v6.description.lowercased() == v6String.lowercased())

    let v4Mapped = try #require(IPAddress(string: v4MappedString))
    #expect(v4Mapped.description.lowercased() == v4MappedString.lowercased())

    do {
      guard case .v4(let b0, let b1, let b2, let b3) = v4 else {
        Issue.record("Not IPv4.")
        return
      }
      #expect(b0 == 127)
      #expect(b1 == 0)
      #expect(b2 == 0)
      #expect(b3 == 1)
    }

    do {
      guard case .v6(let b0, let b1, let  b2, let  b3, let  b4, let  b5, let  b6, let  b7,
                     let b8, let b9, let b10, let b11, let b12, let b13, let b14, let b15) = v6 else {
        Issue.record("Not IPv6.")
        return
      }
      #expect(b0 == 0x12)
      #expect(b1 == 0x34)
      #expect(b2 == 0x56)
      #expect(b3 == 0x78)
      #expect(b4 == 0x90)
      #expect(b5 == 0xAB)
      #expect(b6 == 0xCD)
      #expect(b7 == 0xEF)
      #expect(b8 == 0x12)
      #expect(b9 == 0x34)
      #expect(b10 == 0x56)
      #expect(b11 == 0x78)
      #expect(b12 == 0x90)
      #expect(b13 == 0xAB)
      #expect(b14 == 0xCD)
      #expect(b15 == 0xEF)
    }

    #expect(v4 == v4Mapped)
  }

  @Test func test_DNSReverseLookup() throws {
    let ipAddress = try #require(IPAddress(string: "2001:e42:102:1820:160:16:237:39"))
    #expect(ipAddress.domain == Domain("Choeropsis-liberiensis.YOCKOW.jp"))
  }
}
