/* *************************************************************************************************
 CacheControlDirectiveTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct CacheControlDirectiveTests {
  @Test func test_set() {
    let directives = CacheControlDirectiveSet(.public, .maxAge(19831003))
    #expect(directives.contains(.public))
    #expect(directives.contains(sameCaseWith:.maxAge(0)))
  }

  @Test func test_header() throws {
    let field = HTTPHeaderField(name:.cacheControl, value:"public, max-age=19831003, my-extension=\"my-value\"")
    let set = field.source as? CacheControlDirectiveSet
    _ = try #require(set)
    #expect(set?.contains(.public) == true)
    #expect(set?.contains(.maxAge(19831003)) == true)
    #expect(set?.contains(.extension(name:"my-extension", value:"my-value")) == true)
    #expect(set?.contains(.private) != true)
  }
}
