/***************************************************************************************************
 URL+IDNATests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import Foundation
@testable import NetworkGear
import Testing

private protocol URLIDNATestExpectedComponent {}
extension String: URLIDNATestExpectedComponent {}
extension Int: URLIDNATestExpectedComponent {}

private typealias URLIDNATestExpected = (
  scheme:String?,
  user:String?,
  password:String?,
  host: String,
  port:Int?,
  path:String,
  query:String?,
  fragment:String?,
  absolute:String
)
private typealias URLIDNATestCase = (
  source:String,
  expected:URLIDNATestExpected
)

// https://github.com/swiftlang/swift-foundation/issues/957
@_alwaysEmitIntoClient
private let issue957: Bool = ({ () -> Bool in
#if (compiler(>=6) && compiler(<6.0.3)) && !canImport(Darwin)
  return true
#else
  return false
#endif
})()


private let testCases: [URLIDNATestCase] = [
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
      host: issue957 ? "[::ffff:127.0.0.1]" : "::ffff:127.0.0.1",
      port:80,
      path:"/",
      query:nil,
      fragment:nil,
      absolute:"http://USER:PASSWORD@[::ffff:127.0.0.1]:80/"
    )
  ),
  (
    source: "https://user-without-password@host-without-path",
    expected: (
      scheme: "https",
      user: "user-without-password",
      password: nil,
      host: "host-without-path",
      port: nil,
      path: "",
      query: nil,
      fragment: nil,
      absolute: "https://user-without-password@host-without-path"
    )
  ),
]

@Suite final class URLIDNATests {
  @Test(arguments: testCases)
  fileprivate func test_parser(_ aCase: URLIDNATestCase) throws {
    let components = try #require(InternationalURLStringParser<String>.parse(aCase.source)).output
    #expect(components.scheme == aCase.expected.scheme)
    #expect(components.user == aCase.expected.user)
    #expect(components.password == aCase.expected.password)
    #expect(
      components.host.flatMap({ URL.Host(string: $0)}) ==
      URL.Host(string: aCase.expected.host)
    )
    #expect(components.port == aCase.expected.port)
    #expect(components.path == aCase.expected.path)
    #expect(
      try components.query ==
      aCase.expected.query.map({ try #require($0.removingPercentEncoding) })
    )
    #expect(components.fragment == aCase.expected.fragment)
  }

  @Test(arguments: testCases)
  fileprivate func test_initialization(_ aCase: URLIDNATestCase) throws  {
    let url = try #require(URL(internationalString: aCase.source))
    #expect(url.scheme == aCase.expected.scheme)
    #expect(url.user(percentEncoded: true) == aCase.expected.user)
    #expect(url.password(percentEncoded: true) == aCase.expected.password)
    #expect(url.host(percentEncoded: true) == aCase.expected.host)
    #expect(url.port == aCase.expected.port)
    #expect(url.path(percentEncoded: false) == aCase.expected.path)
    #expect(url.query(percentEncoded: true) == aCase.expected.query)
    #expect(url.fragment(percentEncoded: true) == aCase.expected.fragment)
    #expect(url.absoluteString == aCase.expected.absolute)
  }
}
