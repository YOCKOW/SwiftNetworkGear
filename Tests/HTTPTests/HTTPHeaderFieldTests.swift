/* *************************************************************************************************
 HTTPHeaderFieldTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import NetworkGear

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
    func check_n<D>(_ name:HTTPHeaderFieldName, _ value:HTTPHeaderFieldValue, _ expected:D.Type,
                  file:StaticString = #file, line:UInt = #line)
      where D: HTTPHeaderFieldDelegate
    {
      let field = HTTPHeaderField(name:name, value:value)
      guard case _ as _AnyHTTPHeaderFieldDelegate._Box._Normal<D> = field._delegate._box else {
        XCTFail("Unexpected delegate", file:file, line:line)
        return
      }
    }
    
    func check_a<D>(_ name:HTTPHeaderFieldName, _ value:HTTPHeaderFieldValue, _ expected:D.Type,
                  file:StaticString = #file, line:UInt = #line)
      where D: AppendableHTTPHeaderFieldDelegate
    {
      let field = HTTPHeaderField(name:name, value:value)
      guard case _ as _AnyHTTPHeaderFieldDelegate._Box._Appendable<D> = field._delegate._box else {
        XCTFail("Unexpected delegate", file:file, line:line)
        return
      }
    }
    
    check_n(.contentDisposition, "attachment", ContentDispositionHTTPHeaderFieldDelegate.self)
    check_n(.eTag, "*", HTTPETagHeaderFieldDelegate.self)
    check_n("Etag", "W/\"weak\"", HTTPETagHeaderFieldDelegate.self)
    check_a(.ifMatch, "*", IfMatchHTTPHeaderFieldDelegate.self)
  }
  
  func test_contentLengh() {
    let cl = HTTPHeaderField(name:.contentLength, value:"1024")
    XCTAssertNotNil(cl.source as? UInt)
    XCTAssertEqual(cl.source as? UInt, 1024)
  }
}


