/***************************************************************************************************
 URL+IDNATests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import XCTest
@testable import Network

private protocol URLIDNATestExpectedComponent {}
extension String: URLIDNATestExpectedComponent {}
extension Int: URLIDNATestExpectedComponent {}

private typealias URLIDNATestExpected = (
  scheme:String?,
  user:String?,
  password:String?,
  host:String?,
  port:Int?,
  path:String,
  query:String?,
  fragment:String?,
  absolute:String
)
private typealias URLIDNATestSet = (
  source:String,
  expected:URLIDNATestExpected
)

class URLIDNATests: XCTestCase {
  func testInitialization() {
    let tests:[URLIDNATestSet] = [
      (
        source:"http://YOCKOW.jp/index.xhtml",
        expected:(
          scheme:"http",
          user:nil,
          password:nil,
          host:"yockow.jp",
          port:nil,
          path:"/index.xhtml",
          query:nil,
          fragment:nil,
          absolute:"http://yockow.jp/index.xhtml"
        )
      ),
      (
        source:"https://USER:PASSWORD@にっぽん。ＪＰ:8080/\u{2615}.cgi?杯=2#MyCoffee",
        expected:(
          scheme:"https",
          user:"USER",
          password:"PASSWORD",
          host:"xn--j9jp9cue.jp",
          port:8080,
          path:"/\u{2615}.cgi",
          query:"%E6%9D%AF=2",
          fragment:"MyCoffee",
          absolute:"https://USER:PASSWORD@xn--j9jp9cue.jp:8080/%E2%98%95.cgi?%E6%9D%AF=2#MyCoffee"
        )
      ),
      (
        source:"http://USER:PASSWORD@[::ffff:127.0.0.1]:80/",
        expected:(
          scheme:"http",
          user:"USER",
          password:"PASSWORD",
          host:"::ffff:127.0.0.1",
          port:80,
          path:"/",
          query:nil,
          fragment:nil,
          absolute:"http://USER:PASSWORD@[::ffff:127.0.0.1]:80/"
        )
      )
    ]
    
    
    for test in tests {
      guard let url = URL(internationalString:test.source) else {
        XCTFail("Cannot parse \"\(test.source)\" as a URL.")
        break
      }
      
      let exec = { (expected:URLIDNATestExpectedComponent?, actual:URLIDNATestExpectedComponent?) -> Void in
        let expected_string: String
        let actual_string: String
        
        if case let ee as String = expected {
          expected_string = ee
        } else if case let ee as Int = expected {
          expected_string = String(ee)
        } else {
          expected_string = "`nil`"
        }
        
        if case let aa as String = actual {
          actual_string = aa
        } else if case let aa as Int = actual {
          actual_string = String(aa)
        } else {
          actual_string = "`nil`"
        }
        
        let message = "Expected:\(expected_string), Actual:\(actual_string); URL:\(url.absoluteString)"
        XCTAssertEqual(expected_string, actual_string, message)
      }
      
      exec(test.expected.scheme, url.scheme)
      exec(test.expected.user, url.user)
      exec(test.expected.password, url.password)
      exec(test.expected.host, url.host)
      exec(test.expected.port, url.port)
      exec(test.expected.path, url.path)
      exec(test.expected.query, url.query)
      exec(test.expected.fragment, url.fragment)
      exec(test.expected.absolute, url.absoluteString)
    }
  }
  
  static var allTests = [
    ("testInitialization", testInitialization),
  ]
}

