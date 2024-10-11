/***************************************************************************************************
 URL+HostTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import Foundation
@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class URLHostTests {
  @Test func testInitialization() throws {
    let url1 = try #require(URL(string:"http://www.example.com/"))
    let url2 = try #require(URL(string:"http://[::ffff:127.0.0.1]/"))

    #expect(url1.hostComponent == URL.Host(string:"www.example.com."))
    #expect(url2.hostComponent == URL.Host(string:"127.0.0.1"))
  }

  @Test func test_domainMatching() throws {
    let ipURL = try #require(URL(string:"http://10.0.0.1/path"))
    let domainURL = try #require(URL(string:"http://YOCKOW.JP/path"))
    let subdomainURL = try #require(URL(string:"http://sub.yockow.jp/path"))
    let numberDomainURL = try #require(URL(string:"http://99999999999.jp/path"))
    let numberDomainPlusSubdomainURL = try #require(URL(string:"http://0123.99999999999.jp/path"))

    func __host(of url: URL, sourceLocation: SourceLocation = #_sourceLocation) throws -> URL.Host {
      return try #require(url.hostComponent, sourceLocation: sourceLocation)
    }

    #expect(try !__host(of: ipURL).domainMatches(__host(of: domainURL)))
    #expect(try !__host(of: subdomainURL).domainMatches(__host(of: ipURL)))

    #expect(try !__host(of: domainURL).domainMatches(__host(of: subdomainURL)))
    #expect(try __host(of: subdomainURL).domainMatches(__host(of: domainURL)))

    #expect(try !__host(of: numberDomainURL).domainMatches(__host(of: numberDomainPlusSubdomainURL)))
    #expect(try __host(of: numberDomainPlusSubdomainURL).domainMatches(__host(of: numberDomainURL)))
  }
}
#else
import XCTest

class URLHostTests: XCTestCase {
  func testInitialization() {
    let url1 = URL(string:"http://www.example.com/")!
    let url2 = URL(string:"http://[::ffff:127.0.0.1]/")!
    
    XCTAssertEqual(url1.hostComponent, URL.Host(string:"www.example.com."))
    XCTAssertEqual(url2.hostComponent, URL.Host(string:"127.0.0.1"))
  }
  
  func test_domainMatching() {
    let ipURL = URL(string:"http://10.0.0.1/path")!
    let domainURL = URL(string:"http://YOCKOW.JP/path")!
    let subdomainURL = URL(string:"http://sub.yockow.jp/path")!
    let numberDomainURL = URL(string:"http://99999999999.jp/path")!
    let numberDomainPlusSubdomainURL = URL(string:"http://0123.99999999999.jp/path")!
    
    XCTAssertFalse(ipURL.hostComponent!.domainMatches(domainURL.hostComponent!))
    XCTAssertFalse(subdomainURL.hostComponent!.domainMatches(ipURL.hostComponent!))
    
    XCTAssertFalse(domainURL.hostComponent!.domainMatches(subdomainURL.hostComponent!))
    XCTAssertTrue(subdomainURL.hostComponent!.domainMatches(domainURL.hostComponent!))
    
    XCTAssertFalse(numberDomainURL.hostComponent!.domainMatches(numberDomainPlusSubdomainURL.hostComponent!))
    XCTAssertTrue(numberDomainPlusSubdomainURL.hostComponent!.domainMatches(numberDomainURL.hostComponent!))
  }
}
#endif
