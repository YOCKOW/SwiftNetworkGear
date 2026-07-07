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
    let asctime_string = "Mon Oct  3 16:21:09 1983"
    let incorrect_string = "Mon, 03/Oct/'83 16:21:09 GMT"

    TEST_RFC1123DateParser: do {
      let parsed = try #require(RFC1123DateParser<String>.parse(rfc1123_string)).output
      #expect(parsed.year == 1983)
      #expect(parsed.month == 10)
      #expect(parsed.day == 3)
      #expect(parsed.hour == 16)
      #expect(parsed.minute == 21)
      #expect(parsed.second == 9)
    }

    TEST_TraditionalHTTPCookieDateParser: do {
      let parsed = try #require(TraditionalHTTPCookieDateParser<String>.parse(traditional_string)).output
      #expect(parsed.year == 1983)
      #expect(parsed.month == 10)
      #expect(parsed.day == 3)
      #expect(parsed.hour == 16)
      #expect(parsed.minute == 21)
      #expect(parsed.second == 9)
    }

    TEST_HTTPCookieDateParser: do {
      let parsedRFC1123 = try #require(HTTPCookieDateParser<String>.parse(rfc1123_string)).output
      let parsedTraditional = try #require(HTTPCookieDateParser<String>.parse(traditional_string)).output
      let parsedANSI_C = try #require(HTTPCookieDateParser<String>.parse(asctime_string)).output
      #expect(parsedRFC1123 == parsedTraditional)
      #expect(parsedRFC1123 == parsedANSI_C)
    }

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

  struct __ResponseHeaderTestCase {
    let url: String
    let expectSuccess: Bool
  }
  @Test(
    arguments: Array<__ResponseHeaderTestCase>([
      .init(url: "https://example.net/A/B/C", expectSuccess: false),
      .init(url: "https://example.com/A/B/C/D/E", expectSuccess: true),
      .init(url: "http://sub.example.com/A/B/C/D/E", expectSuccess: true),
      .init(url: "https://com/A/B/C/D/E", expectSuccess: false),
    ])
  )
  func test_responseHeader(case aCase: __ResponseHeaderTestCase) throws {
    let future = Date(timeIntervalSinceNow: 10000.0)
    let futureString = DateFormatter.rfc1123.string(from:future)
    let setCookieValue = try #require(
      HTTPHeaderFieldValue(
        rawValue: "name=value; expires=\(futureString); path=/A/B/C; domain=EXAMPLE.COM; Secure; HttpOnly"
      )
    )

    let url = try #require(URL(string: aCase.url))
    let properties = HTTPCookieProperties(responseHeaderFieldValue: setCookieValue, for: url)
    if !aCase.expectSuccess {
      #expect(properties.isNil)
    } else {
      #expect(properties?.name == "name")
      #expect(properties?.value == "value")
      #expect(properties?.domain == Domain("EXAMPLE.COM")?.description)
      #expect(properties?.path == "/A/B/C")
      #expect(properties?.secure == true)
      #expect(properties?.httpOnly == true)
      #expect(properties?.hostOnly == false)
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
