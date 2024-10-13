/* *************************************************************************************************
 HTTPHeaderFieldTests.swift
   © 2018,2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite struct HTTPHeaderFieldTests {
  @Test func test_name_initialization() {
    #expect(HTTPHeaderFieldName(rawValue:"Space Not Allowed") == nil)
    #expect(HTTPHeaderFieldName(rawValue:"") == nil)
    #expect(HTTPHeaderFieldName(rawValue:"X-My-Original-HTTP-Header-Field-Name") != nil)
  }

  @Test func test_value_initialization() {
    #expect(HTTPHeaderFieldValue(rawValue:"Space and Tab \u{0009} Allowed.") != nil)
    #expect(HTTPHeaderFieldValue(rawValue:"ひらがなは無効です。") == nil)
  }

  @Test func test_initialization() {
    let eTag1 = HTTPETag("\"SomeETag\"")!
    let eTag2 = HTTPETag("W/\"SomeWeakETag\"")!

    let eTagDelegate = HTTPETagHeaderFieldDelegate(eTag1)
    let eTagField = HTTPHeaderField(delegate:eTagDelegate)
    #expect(!eTagField.isAppendable)
    #expect(!eTagField.isDuplicable)
    #expect(eTagField.name == .eTag)
    #expect(eTagField.value == eTag1.httpHeaderFieldValue)

    let ifMatchDelegate = IfMatchHTTPHeaderFieldDelegate(.list([eTag1, eTag2]))
    let ifMatchField = HTTPHeaderField(delegate:ifMatchDelegate)
    #expect(ifMatchField.isAppendable)
    #expect(!ifMatchField.isDuplicable)
    #expect(ifMatchField.name == .ifMatch)
    #expect(ifMatchField.value == HTTPETagList.list([eTag1, eTag2]).httpHeaderFieldValue)
  }

  @Test func test_delegateSelection() {
    func check_n<D>(
      name:HTTPHeaderFieldName,
      value:HTTPHeaderFieldValue,
      userInfo: [AnyHashable: Any]? = nil,
      expected: D.Type,
      sourceLocation: SourceLocation = #_sourceLocation
    ) where D: HTTPHeaderFieldDelegate {
      let field = HTTPHeaderField(name:name, value:value, userInfo: userInfo)
      guard case _ as _AnyHTTPHeaderFieldDelegate._Box._Normal<D> = field._delegate._box else {
        Issue.record("Unexpected delegate", sourceLocation: sourceLocation)
        return
      }
    }

    func check_e<D>(
      name:HTTPHeaderFieldName,
      value:HTTPHeaderFieldValue,
      userInfo: [AnyHashable: Any]? = nil,
      expected: D.Type,
      sourceLocation: SourceLocation = #_sourceLocation
    ) where D: ExternalInformationReferenceableHTTPHeaderFieldDelegate {
      let field = HTTPHeaderField(name:name, value:value, userInfo: userInfo)
      guard case _ as _AnyHTTPHeaderFieldDelegate._Box._Normal<D> = field._delegate._box else {
        Issue.record("Unexpected delegate", sourceLocation: sourceLocation)
        return
      }
    }

    func check_a<D>(
      name: HTTPHeaderFieldName,
      value: HTTPHeaderFieldValue,
      userInfo: [AnyHashable: Any]? = nil,
      expected: D.Type,
      sourceLocation: SourceLocation = #_sourceLocation
    ) where D: AppendableHTTPHeaderFieldDelegate {
      let field = HTTPHeaderField(name:name, value:value, userInfo: userInfo)
      guard case _ as _AnyHTTPHeaderFieldDelegate._Box._Appendable<D> = field._delegate._box else {
        Issue.record("Unexpected delegate", sourceLocation: sourceLocation)
        return
      }
    }

    check_n(name: .contentDisposition, value: "attachment",
            expected: ContentDispositionHTTPHeaderFieldDelegate.self)
    check_n(name: .eTag, value: "*",
            expected: HTTPETagHeaderFieldDelegate.self)
    check_n(name: "Etag", value: "W/\"weak\"",
            expected: HTTPETagHeaderFieldDelegate.self)
    check_a(name: .ifMatch, value: "*",
            expected: IfMatchHTTPHeaderFieldDelegate.self)
    check_n(name: .setCookie, value: "lang=ja; Path=/", userInfo: ["url": "http://example.com/"],
            expected: SetCookieHTTPHeaderFieldDelegate.self)
  }

  @Test func test_contentLengh() {
    let cl = HTTPHeaderField(name:.contentLength, value:"1024")
    #expect(cl.source as? UInt != nil)
    #expect(cl.source as? UInt == 1024)
  }
}
#else
import XCTest

final class HTTPHeaderFieldTests: XCTestCase {
  func test_name_initialization() {
    XCTAssertNil(HTTPHeaderFieldName(rawValue:"Space Not Allowed"))
    XCTAssertNil(HTTPHeaderFieldName(rawValue:""))
    XCTAssertNotNil(HTTPHeaderFieldName(rawValue:"X-My-Original-HTTP-Header-Field-Name"))
  }
  
  func test_value_initialization() {
    XCTAssertNotNil(HTTPHeaderFieldValue(rawValue:"Space and Tab \u{0009} Allowed."))
    XCTAssertNil(HTTPHeaderFieldValue(rawValue:"ひらがなは無効です。"))
  }
  
  func test_initialization() {
    let eTag1 = HTTPETag("\"SomeETag\"")!
    let eTag2 = HTTPETag("W/\"SomeWeakETag\"")!
    
    let eTagDelegate = HTTPETagHeaderFieldDelegate(eTag1)
    let eTagField = HTTPHeaderField(delegate:eTagDelegate)
    XCTAssertFalse(eTagField.isAppendable)
    XCTAssertFalse(eTagField.isDuplicable)
    XCTAssertEqual(eTagField.name, .eTag)
    XCTAssertEqual(eTagField.value, eTag1.httpHeaderFieldValue)
    
    let ifMatchDelegate = IfMatchHTTPHeaderFieldDelegate(.list([eTag1, eTag2]))
    let ifMatchField = HTTPHeaderField(delegate:ifMatchDelegate)
    XCTAssertTrue(ifMatchField.isAppendable)
    XCTAssertFalse(ifMatchField.isDuplicable)
    XCTAssertEqual(ifMatchField.name, .ifMatch)
    XCTAssertEqual(ifMatchField.value, HTTPETagList.list([eTag1, eTag2]).httpHeaderFieldValue)
  }
  
  func test_delegateSelection() {
    func check_n<D>(
      name:HTTPHeaderFieldName,
      value:HTTPHeaderFieldValue,
      userInfo: [AnyHashable: Any]? = nil,
      expected: D.Type,
      file: StaticString = #file, line: UInt = #line
    ) where D: HTTPHeaderFieldDelegate {
      let field = HTTPHeaderField(name:name, value:value, userInfo: userInfo)
      guard case _ as _AnyHTTPHeaderFieldDelegate._Box._Normal<D> = field._delegate._box else {
        XCTFail("Unexpected delegate", file:file, line:line)
        return
      }
    }

    func check_e<D>(
      name:HTTPHeaderFieldName,
      value:HTTPHeaderFieldValue,
      userInfo: [AnyHashable: Any]? = nil,
      expected: D.Type,
      file: StaticString = #file, line: UInt = #line
    ) where D: ExternalInformationReferenceableHTTPHeaderFieldDelegate {
      let field = HTTPHeaderField(name:name, value:value, userInfo: userInfo)
      guard case _ as _AnyHTTPHeaderFieldDelegate._Box._Normal<D> = field._delegate._box else {
        XCTFail("Unexpected delegate", file:file, line:line)
        return
      }
    }
    
    func check_a<D>(
      name: HTTPHeaderFieldName,
      value: HTTPHeaderFieldValue,
      userInfo: [AnyHashable: Any]? = nil,
      expected: D.Type,
      file: StaticString = #file, line: UInt = #line
    ) where D: AppendableHTTPHeaderFieldDelegate {
      let field = HTTPHeaderField(name:name, value:value, userInfo: userInfo)
      guard case _ as _AnyHTTPHeaderFieldDelegate._Box._Appendable<D> = field._delegate._box else {
        XCTFail("Unexpected delegate", file:file, line:line)
        return
      }
    }
    
    check_n(name: .contentDisposition, value: "attachment",
            expected: ContentDispositionHTTPHeaderFieldDelegate.self)
    check_n(name: .eTag, value: "*",
            expected: HTTPETagHeaderFieldDelegate.self)
    check_n(name: "Etag", value: "W/\"weak\"",
            expected: HTTPETagHeaderFieldDelegate.self)
    check_a(name: .ifMatch, value: "*",
            expected: IfMatchHTTPHeaderFieldDelegate.self)
    check_n(name: .setCookie, value: "lang=ja; Path=/", userInfo: ["url": "http://example.com/"],
            expected: SetCookieHTTPHeaderFieldDelegate.self)
  }
  
  func test_contentLengh() {
    let cl = HTTPHeaderField(name:.contentLength, value:"1024")
    XCTAssertNotNil(cl.source as? UInt)
    XCTAssertEqual(cl.source as? UInt, 1024)
  }
}
#endif
