/* *************************************************************************************************
 CacheControlDirectiveTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
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
#else
import XCTest

final class CacheControlDirectiveTests: XCTestCase {
  func test_set() {
    let directives = CacheControlDirectiveSet(.public, .maxAge(19831003))
    XCTAssertTrue(directives.contains(.public))
    XCTAssertTrue(directives.contains(sameCaseWith:.maxAge(0)))
  }
  
  func test_header() {
    let field = HTTPHeaderField(name:.cacheControl, value:"public, max-age=19831003, my-extension=\"my-value\"")
    let set = field.source as? CacheControlDirectiveSet
    XCTAssertNotNil(set)
    XCTAssertEqual(set?.contains(.public), true)
    XCTAssertEqual(set?.contains(.maxAge(19831003)), true)
    XCTAssertEqual(set?.contains(.extension(name:"my-extension", value:"my-value")), true)
    XCTAssertNotEqual(set?.contains(.private), true)
  }
}
#endif
