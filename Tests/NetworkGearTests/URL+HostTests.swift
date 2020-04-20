/***************************************************************************************************
 URL+HostTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import XCTest
@testable import NetworkGear

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




