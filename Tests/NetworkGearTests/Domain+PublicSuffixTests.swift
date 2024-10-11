/***************************************************************************************************
 Domain+PublicSuffixTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class DomainPublicSuffixTests {
  @Test func test_publicSuffix() {
    // how to test...
    // Public Suffix List is fluid.

    let domain1 = Domain("YOCKOW.JP")!

    #expect(!domain1.isPublicSuffix)
    #expect(domain1.publicSuffix == Domain("jp"))
    #expect(domain1.dropPublicSuffix() == Domain("YOCKOW"))

    let domain2 = Domain("東京.jp")!
    #expect(domain2.isPublicSuffix)
    #expect(domain2.publicSuffix == Domain("東京.jp"))
    #expect(domain2.dropPublicSuffix() == nil)

    let domain3 = Domain("city.Yokohama.jp")!
    #expect(!domain3.isPublicSuffix)
    #expect(domain3.publicSuffix == Domain("jp"))
    #expect(domain3.dropPublicSuffix() == Domain("city.yokohama"))
  }
}
#else
import XCTest

final class DomainPublicSuffixTests: XCTestCase {
  func test_publicSuffix() {
    // how to test...
    // Public Suffix List is fluid.
    
    let domain1 = Domain("YOCKOW.JP")!
    
    XCTAssertFalse(domain1.isPublicSuffix)
    XCTAssertEqual(domain1.publicSuffix, Domain("jp"))
    XCTAssertEqual(domain1.dropPublicSuffix(), Domain("YOCKOW"))
    
    let domain2 = Domain("東京.jp")!
    XCTAssertTrue(domain2.isPublicSuffix)
    XCTAssertEqual(domain2.publicSuffix, Domain("東京.jp"))
    XCTAssertEqual(domain2.dropPublicSuffix(), nil)
    
    let domain3 = Domain("city.Yokohama.jp")!
    XCTAssertFalse(domain3.isPublicSuffix)
    XCTAssertEqual(domain3.publicSuffix, Domain("jp"))
    XCTAssertEqual(domain3.dropPublicSuffix(), Domain("city.yokohama"))
    
  }
}
#endif
