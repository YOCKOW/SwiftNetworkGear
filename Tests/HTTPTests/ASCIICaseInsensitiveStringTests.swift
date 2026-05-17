/* *************************************************************************************************
 ASCIICaseInsensitiveStringTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct ASCIICaseInsensitiveStringTests {
  @Test func test_prefix() {
    #expect(ASCIICaseInsensitiveString("AbC").hasPrefix("a"))
    #expect(ASCIICaseInsensitiveString("AbC").hasPrefix("aB"))
    #expect(ASCIICaseInsensitiveString("AbC").hasPrefix("aBc"))
    #expect(!ASCIICaseInsensitiveString("AbC").hasPrefix("aBcD"))
    #expect(!ASCIICaseInsensitiveString("").hasPrefix("1"))
    #expect(!ASCIICaseInsensitiveString("DEF").hasPrefix("abc"))
  }
}
