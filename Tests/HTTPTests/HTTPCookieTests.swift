/* *************************************************************************************************
 HTTPCookieTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite struct HTTPCookieTests {
  @Test func test_date() throws {
    let rfc1123_string = "Mon, 03 Oct 1983 16:21:09 GMT"
    let traditional_string = "Mon, 03-Oct-1983 16:21:09 GMT"
    let incorrect_string = "Mon, 03/Oct/'83 16:21:09 GMT"

    let fromRFC1123 = Date(cookieDateString:rfc1123_string)
    let fromTraditional = Date(cookieDateString:traditional_string)
    let fromIncorrect = Date(cookieDateString:incorrect_string)

    _ = try #require(fromRFC1123)
    #expect(fromRFC1123 == fromTraditional)
    #expect(fromRFC1123 == fromIncorrect)
  }

  @Test func test_requestHeader() {
    let propertiesList: Array<[HTTPCookiePropertyKey:Any]> = [
      [.domain:"example.com", .path:"/"],
      [.domain:"example.com", .path:"/", .secure:true],
      [.domain:"example.com", .path:"/a/b", .secure:true],
      [.domain:"example.com", .path:"/", .secure:true, .hostOnly:true],
      [.domain:"example.com", .path:"/", .expires:Date(timeIntervalSinceNow:-100.0)]
    ]

    let urlStrings:[String] = [
      "http://example.com/",
      "https://example.com/",
      "http://www.example.com/a/b/c",
      "https://www.example.com/a/b/c"
    ]

    let tests: [(Int, Int, Bool)] = [
      // (index of `propertiesList`, index of `urlStrings`, whether field value can be gotten)
      // not all cases
      (0,0,true), (0,1,true), (0,2,true), (0,3,true),
      (1,0,false), (1,1,true), (1,2,false), (1,3,true),
      (2,1,false), (2,3,true),
      (3,1,true), (3,3,false),
      (4,1,false), (4,3,false),
    ]

    for ii in 0..<tests.count {
      let test = tests[ii]

      var properties = propertiesList[test.0]
      let url = URL(string:urlStrings[test.1])!

      properties[.name] = "name"
      properties[.value] = "value"

      let cookie = AnyHTTPCookie(properties: HTTPCookieProperties(properties))!
      #expect(cookie.canBeSent(to:url) == test.2, "#\(ii)")
    }
  }

  @Test func test_responseHeader() throws {
    let future = Date(timeIntervalSinceNow:10000.0)
    let future_string = DateFormatter.rfc1123.string(from:future)
    let setCookieValue = HTTPHeaderFieldValue(rawValue:
      "name=value; expires=\(future_string); path=/A/B/C; domain=EXAMPLE.COM; Secure; HttpOnly"
    )!

    let cases:[(String, Bool, SourceLocation)] = [
      ("https://example.net/A/B/C", false, #_sourceLocation),
      ("https://example.com/A/B/C/D/E", true, #_sourceLocation),
      ("http://sub.example.com/A/B/C/D/E", true, #_sourceLocation),
      ("https://com/A/B/C/D/E", false, #_sourceLocation),
    ]

    for test in cases {
      let properties =
        HTTPCookieProperties(responseHeaderFieldValue:setCookieValue, for:URL(string:test.0)!)
      if !test.1 {
        #expect(properties == nil, sourceLocation: test.2)
      } else {
        let properties = try #require(properties, sourceLocation: test.2)
        #expect(properties.name == "name", sourceLocation: test.2)
        #expect(properties.value == "value", sourceLocation: test.2)
        #expect(properties.domain == Domain("EXAMPLE.COM")?.description, sourceLocation: test.2)
        #expect(properties.path == "/A/B/C", sourceLocation: test.2)
        #expect(properties.secure, sourceLocation: test.2)
        #expect(properties.httpOnly, sourceLocation: test.2)
        #expect(properties.hostOnly == false, sourceLocation: test.2)
      }
    }
  }

  @Test func test_setCookieHeaderField() throws {
    let setCookie = HTTPHeaderField(name:.setCookie, value:"name=value; domain=YOCKOW.jp; path=/path")
    let cookie = try #require(setCookie.source as? SetCookieHTTPHeaderFieldDelegate.Cookie)
    #expect(cookie.name == "name")
    #expect(cookie.value == "value")
    #expect(cookie.domain.lowercased() == "YOCKOW.jp".lowercased())
    #expect(cookie.path == "/path")
  }
}
#else
import XCTest

final class HTTPCookieTests: XCTestCase {
  func test_date() {
    let rfc1123_string = "Mon, 03 Oct 1983 16:21:09 GMT"
    let traditional_string = "Mon, 03-Oct-1983 16:21:09 GMT"
    let incorrect_string = "Mon, 03/Oct/'83 16:21:09 GMT"
    
    let fromRFC1123 = Date(cookieDateString:rfc1123_string)
    let fromTraditional = Date(cookieDateString:traditional_string)
    let fromIncorrect = Date(cookieDateString:incorrect_string)
    
    XCTAssertNotNil(fromRFC1123)
    XCTAssertEqual(fromRFC1123, fromTraditional)
    XCTAssertEqual(fromRFC1123, fromIncorrect)
  }
  
  func test_requestHeader() {
    let propertiesList: Array<[HTTPCookiePropertyKey:Any]> = [
      [.domain:"example.com", .path:"/"],
      [.domain:"example.com", .path:"/", .secure:true],
      [.domain:"example.com", .path:"/a/b", .secure:true],
      [.domain:"example.com", .path:"/", .secure:true, .hostOnly:true],
      [.domain:"example.com", .path:"/", .expires:Date(timeIntervalSinceNow:-100.0)]
    ]
    
    let urlStrings:[String] = [
      "http://example.com/",
      "https://example.com/",
      "http://www.example.com/a/b/c",
      "https://www.example.com/a/b/c"
    ]
    
    let tests: [(Int, Int, Bool)] = [
      // (index of `propertiesList`, index of `urlStrings`, whether field value can be gotten)
      // not all cases
      (0,0,true), (0,1,true), (0,2,true), (0,3,true),
      (1,0,false), (1,1,true), (1,2,false), (1,3,true),
      (2,1,false), (2,3,true),
      (3,1,true), (3,3,false),
      (4,1,false), (4,3,false),
    ]
    
    for ii in 0..<tests.count {
      let test = tests[ii]
      
      var properties = propertiesList[test.0]
      let url = URL(string:urlStrings[test.1])!
      
      properties[.name] = "name"
      properties[.value] = "value"
      
      let cookie = AnyHTTPCookie(properties: HTTPCookieProperties(properties))!
      XCTAssertEqual(cookie.canBeSent(to:url), test.2, "#\(ii)")
    }
  }
  
  func test_responseHeader() {
    let future = Date(timeIntervalSinceNow:10000.0)
    let future_string = DateFormatter.rfc1123.string(from:future)
    let setCookieValue = HTTPHeaderFieldValue(rawValue:
      "name=value; expires=\(future_string); path=/A/B/C; domain=EXAMPLE.COM; Secure; HttpOnly"
    )!
    
    let cases:[(String,Bool,StaticString,UInt)] = [
      ("https://example.net/A/B/C", false, #file, #line),
      ("https://example.com/A/B/C/D/E", true, #file, #line),
      ("http://sub.example.com/A/B/C/D/E", true, #file, #line),
      ("https://com/A/B/C/D/E", false, #file, #line),
    ]
    
    for test in cases {
      let properties =
        HTTPCookieProperties(responseHeaderFieldValue:setCookieValue, for:URL(string:test.0)!)
      if !test.1 {
        XCTAssertNil(properties, file:test.2, line:test.3)
      } else {
        XCTAssertNotNil(properties, file:test.2, line:test.3)
        XCTAssertEqual(properties?.name, "name", file:test.2, line:test.3)
        XCTAssertEqual(properties?.value, "value", file:test.2, line:test.3)
        XCTAssertEqual(properties?.domain, Domain("EXAMPLE.COM")?.description, file:test.2, line:test.3)
        XCTAssertEqual(properties?.path, "/A/B/C", file:test.2, line:test.3)
        XCTAssertEqual(properties?.secure, true, file:test.2, line:test.3)
        XCTAssertEqual(properties?.httpOnly, true, file:test.2, line:test.3)
        XCTAssertEqual(properties?.hostOnly, false, file:test.2, line:test.3)
      }
    }
  }
  
  func test_setCookieHeaderField() {
    let setCookie = HTTPHeaderField(name:.setCookie, value:"name=value; domain=YOCKOW.jp; path=/path")
    let cookie = setCookie.source as? SetCookieHTTPHeaderFieldDelegate.Cookie
    XCTAssertNotNil(cookie)
    XCTAssertEqual(cookie?.name, "name")
    XCTAssertEqual(cookie?.value, "value")
    XCTAssertEqual(cookie?.domain.lowercased(), "YOCKOW.jp".lowercased())
    XCTAssertEqual(cookie?.path, "/path")
  }
}
#endif
