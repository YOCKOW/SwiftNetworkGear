/***************************************************************************************************
 Domain+PublicSuffixTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import XCTest
@testable import Network

final class DomainPublicSuffixTests: XCTestCase {
  func test() {
    // how to test...
    // Public Suffix List is fluid.
    
    let domain1 = Domain("YOCKOW.JP")!
    
    XCTAssertFalse(domain1.isPublicSuffix)
    XCTAssertEqual(domain1.publicSuffix, Domain("jp"))
    
    let domain2 = Domain("東京.jp")!
    XCTAssertTrue(domain2.isPublicSuffix)
    XCTAssertEqual(domain2.publicSuffix, Domain("東京.jp"))
  }
  
  static var allTests = [
    ("test", test),
  ]
}

