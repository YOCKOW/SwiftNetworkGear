/* *************************************************************************************************
 MIMESafeDataTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
@testable import NetworkGear
import Testing

@Suite struct UInt7Tests {
  @Test func test_init() {
    #expect(UInt7(0) == .zero)
    #expect(UInt7(exactly: 0x7F as Int) == 0x7F)
    #expect(UInt7(UInt8(0x80)) == .zero)
  }

  @Test func test_arithmetic() {
    #expect(UInt7(0x20) + 0x41 == UInt7(0x61))
    #expect(UInt7(0x61) - 0x20 == UInt7(0x41))
    #expect(UInt7(2) * 3 == UInt7(6))
    #expect(UInt7(6) / 3 == UInt7(2))
  }
}

@Suite struct MIMESafeDataTests {
  @Test func test_init() {
    #expect(MIMESafeData(data: Data([0x80, 0x81])).isNil)
    #expect(MIMESafeData(data: Data([0x30, 0x31]))?.count == 2)
    #expect(MIMESafeData(contentsOf: [0x30, 0x31]) == MIMESafeData(data: Data([0x30, 0x31])))
  }

  @Test func test_asCollection() {
    var data = MIMESafeData()
    (UInt7.zero...UInt7.max).forEach({ data.append($0) })

    #expect(data.count == 128)
    #expect(data[0x41] == 0x41)
  }

  @Test func test_String() {
    #expect(String(data: MIMESafeData([0x41, 0x42, 0x63])) == "ABc")
  }
}
