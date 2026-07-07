/***************************************************************************************************
 IPAddressTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

@testable import NetworkGear
import Testing
import yExtensions

@Suite final class IPAddressTests {
  @Test func test_IPv4AddressParser() {
    #expect(IPv4AddressParser<String>.parse("127.0.0.1")?.output.description == "127.0.0.1")
    #expect(IPv4AddressParser<String>.parse("255.255.255.255")?.output.description == "255.255.255.255")
    #expect(IPv4AddressParser<String>.parse("321.0.0.0").isNil)
  }

  @Test(arguments: [
    ("invalid-string", nil),
    (":", nil),
    // ⑴                            6( h16 ":" ) ls32
    ("1:2:3:4:5:6:7:8", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8)),
    ("1:2:3:4:A:B:C:D", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 0xA, 0, 0xB, 0, 0xC, 0, 0xd)),
    ("A:B:C:D:E:F:192.168.1.1", .v6(0, 0xA, 0, 0xB, 0,0xC, 0, 0xD, 0, 0xE, 0, 0xF, 192, 168, 1, 1)),
    // ⑵                       "::" 5( h16 ":" ) ls32
    ("::1:2:3:4:5:A:B", .v6(0, 0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 0xA, 0, 0xB)),
    ("::1:2:3:4:5:127.0.0.1", .v6(0, 0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 127, 0, 0, 1)),
    // ⑶ [               h16 ] "::" 4( h16 ":" ) ls32
    ("::1111:2222:3333:4444:AAAA:BBBB", .v6(0, 0, 0, 0, 0x11, 0x11, 0x22, 0x22, 0x33, 0x33, 0x44, 0x44, 0xAA, 0xAA, 0xBB, 0xBB)),
    ("::1111:2222:3333:4444:127.0.0.1", .v6(0, 0, 0, 0, 0x11, 0x11, 0x22, 0x22, 0x33, 0x33, 0x44, 0x44, 127, 0, 0, 1)),
    ("1234::AAAA:BBBB:CCCC:DDDD:EEEE:FFFF", .v6(0x12, 0x34, 0, 0, 0xAA, 0xAA, 0xBB, 0xBB, 0xCC, 0xCC, 0xDD, 0xDD, 0xEE, 0xEE, 0xFF, 0xFF)),
    ("1234::AAAA:BBBB:CCCC:DDDD:10.0.0.1", .v6(0x12, 0x34, 0, 0, 0xAA, 0xAA, 0xBB, 0xBB, 0xCC, 0xCC, 0xDD, 0xDD, 10, 0, 0, 1)),
    // ⑷ [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
    ("::0101:0202:0303:0A0A:0B0B", .v6(0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 0xA, 0xA, 0xB, 0xB)),
    ("::0101:0202:0303:10.10.11.11", .v6(0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 0xA, 0xA, 0xB, 0xB)),
    ("1::A:B:C:D:E", .v6(0, 1, 0, 0, 0, 0, 0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD, 0, 0xE)),
    ("1::A:B:C:2.3.4.5", .v6(0, 1, 0, 0, 0, 0, 0, 0xA, 0, 0xB, 0, 0xC, 2, 3, 4, 5)),
    ("1:2::A:B:C:D:E", .v6(0, 1, 0, 2, 0, 0, 0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD, 0, 0xE)),
    ("1:2::A:B:C:3.4.5.6", .v6(0, 1, 0, 2, 0, 0, 0, 0xA, 0, 0xB, 0, 0xC, 3, 4, 5, 6)),
    // ⑸ [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
    ("::A:B:C:D", .v6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD)),
    ("::A:B:1.2.3.4", .v6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0xA, 0, 0xB, 1, 2, 3, 4)),
    ("1::A:B:C:D", .v6(0, 1, 0, 0, 0, 0, 0, 0, 0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD)),
    ("1::A:B:2.3.4.5", .v6(0, 1, 0, 0, 0, 0, 0, 0, 0, 0xA, 0, 0xB, 2, 3, 4, 5)),
    ("1:2::A:B:C:D", .v6(0, 1, 0, 2, 0, 0, 0, 0, 0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD)),
    ("1:2::A:B:3.4.5.6", .v6(0, 1, 0, 2, 0, 0, 0, 0, 0, 0xA, 0, 0xB, 3, 4, 5, 6)),
    ("1:2:3::A:B:C:D", .v6(0, 1, 0, 2, 0, 3, 0, 0, 0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD)),
    ("1:2:3::A:B:4.5.6.7", .v6(0, 1, 0, 2, 0, 3, 0, 0, 0, 0xA, 0, 0xB, 4, 5, 6, 7)),
    // ⑹ [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
    ("::AAAA:BBBB:CCCC", .v6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xAA, 0xAA, 0xBB, 0xBB, 0xCC, 0xCC)),
    ("::AAAA:255.255.255.255", .v6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xAA, 0xAA, 255, 255, 255, 255)),
    ("1::AAAA:BBBB:CCCC", .v6(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0xAA, 0xAA, 0xBB, 0xBB, 0xCC, 0xCC)),
    ("1::AAAA:255.255.255.255", .v6(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0xAA, 0xAA, 255, 255, 255, 255)),
    ("1:2::AAAA:BBBB:CCCC", .v6(0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0xAA, 0xAA, 0xBB, 0xBB, 0xCC, 0xCC)),
    ("1:2::AAAA:255.255.255.255", .v6(0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0xAA, 0xAA, 255, 255, 255, 255)),
    ("1:2:3::AAAA:BBBB:CCCC", .v6(0, 1, 0, 2, 0, 3, 0, 0, 0, 0, 0xAA, 0xAA, 0xBB, 0xBB, 0xCC, 0xCC)),
    ("1:2:3::AAAA:255.255.255.255", .v6(0, 1, 0, 2, 0, 3, 0, 0, 0, 0, 0xAA, 0xAA, 255, 255, 255, 255)),
    ("1:2:3:4::AAAA:BBBB:CCCC", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 0, 0xAA, 0xAA, 0xBB, 0xBB, 0xCC, 0xCC)),
    ("1:2:3:4::AAAA:255.255.255.255", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 0, 0xAA, 0xAA, 255, 255, 255, 255)),
    // ⑺ [ *4( h16 ":" ) h16 ] "::"              ls32
    ("::A0A:B0B", .v6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xA, 0xA, 0xB, 0xB)),
    ("::4.5.0.0", .v6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0)),
    ("1::A0A:B0B", .v6(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xA, 0xA, 0xB, 0xB)),
    ("1::4.5.0.0", .v6(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0)),
    ("1:2::A0A:B0B", .v6(0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0xA, 0xA, 0xB, 0xB)),
    ("1:2::4.5.0.0", .v6(0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0)),
    ("1:2:3::A0A:B0B", .v6(0, 1, 0, 2, 0, 3, 0, 0, 0, 0, 0, 0, 0xA, 0xA, 0xB, 0xB)),
    ("1:2:3::4.5.0.0", .v6(0, 1, 0, 2, 0, 3, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0)),
    ("1:2:3:4::A0A:B0B", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 0, 0, 0, 0xA, 0xA, 0xB, 0xB)),
    ("1:2:3:4::4.5.0.0", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 0, 0, 0, 4, 5, 0, 0)),
    ("1:2:3:4:5::A0A:B0B", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 0, 0xA, 0xA, 0xB, 0xB)),
    ("1:2:3:4:5::4.5.0.0", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 0, 4, 5, 0, 0)),
    // ⑻ [ *5( h16 ":" ) h16 ] "::"              h16
    ("::A", .v6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xA)),
    ("1::A", .v6(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xA)),
    ("1:2::A", .v6(0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xA)),
    ("1:2:3::A", .v6(0, 1, 0, 2, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xA)),
    ("1:2:3:4::A", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0xA)),
    ("1:2:3:4:5::A", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 0, 0, 0, 0, 0xA)),
    ("1:2:3:4:5:6::A", .v6(0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 0, 0, 0xA)),
    // ⑼ [ *6( h16 ":" ) h16 ] "::"
    ("::", .v6(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ("A::", .v6(0, 0xA, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ("A:B::", .v6(0, 0xA, 0, 0xB, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ("A:B:C::", .v6(0, 0xA, 0, 0xB, 0, 0xC, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ("A:B:C:D::", .v6(0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD, 0, 0, 0, 0, 0, 0, 0, 0)),
    ("A:B:C:D:E::", .v6(0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD, 0, 0xE, 0, 0, 0, 0, 0, 0)),
    ("A:B:C:D:E:F::", .v6(0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD, 0, 0xE, 0, 0xF, 0, 0, 0, 0)),
    ("A:B:C:D:E:F:1::", .v6(0, 0xA, 0, 0xB, 0, 0xC, 0, 0xD, 0, 0xE, 0, 0xF, 0, 1, 0, 0)),
  ] as Array<(string: String, expected: IPAddress?)>)
  func test_IPv6AddressParser(_ pair: (string: String, expected: IPAddress?)) {
    let ipAddress = IPv6AddressParser<String>.parse(pair.string)?.output
    #expect(ipAddress == pair.expected)

    let enclosed = IPv6AddressParser<String>.parse("[\(pair.string)]")?.output
    #expect(enclosed == pair.expected)
  }

  @Test func test_IPvFutureAddressParser() throws {
    #expect(
      try #require(IPvFutureAddressParser<String>.parse("vFF.foo:bar:baz")?.output) ==
      IPvFutureAddress(version: 0xFF, stringRepresentation: "foo:bar:baz")
   )
  }

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
