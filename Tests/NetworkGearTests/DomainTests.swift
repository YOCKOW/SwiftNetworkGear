/***************************************************************************************************
 DomainTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class DomainTests {
  @Test func testInitialization() throws {
    let tests: [(String, String, Domain.Label.ValidityOptions)] = [
      ("YOCKOW.jp", "yockow.jp", .default),
      ("日本。ＪＰ", "xn--wgv71a.jp", .default),
      ("EXAMPLE.COM.", "example.com.", .idna2008),
      ("9999999999999999999999.NET", "9999999999999999999999.net", [])
    ]

    for test in tests {
      let domain = try #require(Domain(test.0, options:test.2))
      #expect(domain.description == test.1)
    }
  }

  @Test func test_domainMatching() throws {
    let myDomain = Domain("Sub.YOCKOW.jp")!

    #expect(myDomain.domainMatches(try #require(Domain("yockow.jp"))))
    #expect(myDomain.domainMatches(try #require(Domain("sub.yockow.jp"))))

    #expect(!myDomain.domainMatches(try #require(Domain("another.sub.yockow.jp"))))
    #expect(!myDomain.domainMatches(try #require(Domain("foosub.yockow.jp"))))
    #expect(!myDomain.domainMatches(try #require(Domain(("baryockow.jp")))))
  }

  @Test func test_asCollection() throws {
    let domain = try #require(Domain("foo.bar.baz.example.com"))

    #expect(try #require(domain.first) == "foo")
    #expect(try #require(domain.last) == "com")
    #expect(domain.prefix(2) == Domain("foo.bar"))
    #expect(domain.suffix(2) == Domain("example.com"))
  }

  @Test func test_static() {
    let localhost = Domain.localhost
    #expect(localhost.description == "localhost")
  }
}
#else
import XCTest

final class DomainTests: XCTestCase {
  func testInitialization() {
    let tests: [(String, String, Domain.Label.ValidityOptions)] = [
      ("YOCKOW.jp", "yockow.jp", .default),
      ("日本。ＪＰ", "xn--wgv71a.jp", .default),
      ("EXAMPLE.COM.", "example.com.", .idna2008),
      ("9999999999999999999999.NET", "9999999999999999999999.net", [])
    ]
    
    for test in tests {
      let domain = Domain(test.0, options:test.2)
      XCTAssertNotNil(domain)
      XCTAssertEqual(domain!.description, test.1)
    }
  }
  
  func test_domainMatching() {
    let myDomain = Domain("Sub.YOCKOW.jp")!
    
    XCTAssertTrue(myDomain.domainMatches(Domain("yockow.jp")!))
    XCTAssertTrue(myDomain.domainMatches(Domain("sub.yockow.jp")!))
    
    XCTAssertFalse(myDomain.domainMatches(Domain("another.sub.yockow.jp")!))
    XCTAssertFalse(myDomain.domainMatches(Domain("foosub.yockow.jp")!))
    XCTAssertFalse(myDomain.domainMatches(Domain("baryockow.jp")!))
  }
  
  func test_asCollection() throws {
    let domain = Domain("foo.bar.baz.example.com")!
    
    XCTAssertTrue(domain.first! == "foo")
    XCTAssertTrue(domain.last! == "com")
    XCTAssertEqual(domain.prefix(2), Domain("foo.bar"))
    XCTAssertEqual(domain.suffix(2), Domain("example.com"))
  }

  func test_static() {
    let localhost = Domain.localhost
    XCTAssertEqual(localhost.description, "localhost")
  }
}
#endif
