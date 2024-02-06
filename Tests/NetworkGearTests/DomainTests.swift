/***************************************************************************************************
 DomainTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import XCTest
@testable import NetworkGear

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

