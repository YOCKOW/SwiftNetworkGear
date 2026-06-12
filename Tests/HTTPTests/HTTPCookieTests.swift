/* *************************************************************************************************
 HTTPCookieTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import NetworkGear
import Testing
import yExtensions

@Suite struct HTTPCookieTests {
  @Test func test_WeekdayParser() {
    #expect(Weekday("foo").isNil)

    #expect(Weekday("Sun") == .sunday)
    #expect(Weekday("Sund").isNil)
    #expect(Weekday("Sunday") == .sunday)

    #expect(Weekday("Mon") == .monday)
    #expect(Weekday("Mond").isNil)
    #expect(Weekday("Monday") == .monday)

    #expect(Weekday("Tue") == .tuesday)
    #expect(Weekday("Tues") == .tuesday)
    #expect(Weekday("Tuesd").isNil)
    #expect(Weekday("Tuesday") == .tuesday)

    #expect(Weekday("Wed") == .wednesday)
    #expect(Weekday("Wedne").isNil)
    #expect(Weekday("Wednesday") == .wednesday)

    #expect(Weekday("Thu") == .thursday)
    #expect(Weekday("Thur") == .thursday)
    #expect(Weekday("Thurs") == .thursday)
    #expect(Weekday("Thursd").isNil)
    #expect(Weekday("Thursday") == .thursday)

    #expect(Weekday("Fri") == .friday)
    #expect(Weekday("Frid").isNil)
    #expect(Weekday("Friday") == .friday)

    #expect(Weekday("Sat") == .saturday)
    #expect(Weekday("Satu").isNil)
    #expect(Weekday("Satur").isNil)
    #expect(Weekday("Saturday") == .saturday)
  }

  @Test func test_MonthNameParser() {
    #expect(Month("foo").isNil)

    #expect(Month("Jan") == .january)
    #expect(Month("Janu").isNil)
    #expect(Month("January") == .january)

    #expect(Month("Feb") == .february)
    #expect(Month("Febr").isNil)
    #expect(Month("February") == .february)

    #expect(Month("Mar") == .march)
    #expect(Month("Marc").isNil)
    #expect(Month("March") == .march)

    #expect(Month("Apr") == .april)
    #expect(Month("Apri").isNil)
    #expect(Month("April") == .april)

    #expect(Month("May") == .may)
    #expect(Month("Mayday").isNil)

    #expect(Month("Jun") == .june)
    #expect(Month("Junee").isNil)
    #expect(Month("June") == .june)

    #expect(Month("Jul") == .july)
    #expect(Month("Juli").isNil)
    #expect(Month("July") == .july)

    #expect(Month("Aug") == .august)
    #expect(Month("Augu").isNil)
    #expect(Month("August") == .august)

    #expect(Month("Sep") == .september)
    #expect(Month("Sept").isNil)
    #expect(Month("September") == .september)

    #expect(Month("Oct") == .october)
    #expect(Month("Octo").isNil)
    #expect(Month("October") == .october)

    #expect(Month("Nov") == .november)
    #expect(Month("Nove").isNil)
    #expect(Month("November") == .november)

    #expect(Month("Dec") == .december)
    #expect(Month("Dece").isNil)
    #expect(Month("December") == .december)
  }

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
