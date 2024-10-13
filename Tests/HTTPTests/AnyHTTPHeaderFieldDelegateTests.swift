/* *************************************************************************************************
 AnyHTTPHeaderFieldDelegateTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite struct AnyHTTPHeaderFieldDelegateTests {
  @Test func test_initializer() throws {
    let any1 = _AnyHTTPHeaderFieldDelegate(HTTPETagHeaderFieldDelegate(HTTPETag("*")!))
    #expect(any1.type == .single)
    #expect(any1.name == .eTag)
    #expect(try any1.value == #require(HTTPHeaderFieldValue(rawValue:"*")))


    var any2 = _AnyHTTPHeaderFieldDelegate(IfMatchHTTPHeaderFieldDelegate(try HTTPETagList("\"A\"")))
    any2.append(HTTPETag("\"B\"")!)
    #expect(any2.type == .appendable)
    #expect(any2.name == .ifMatch)
    #expect(any2.value == HTTPHeaderFieldValue(rawValue:"\"A\", \"B\"")!)

    let unspecified = _AnyHTTPHeaderFieldDelegate(
      name: try #require(HTTPHeaderFieldName(rawValue:"Foo")),
      value: try #require(HTTPHeaderFieldValue(rawValue:"Bar"))
    )
    #expect(unspecified.type == .single)
    #expect(try unspecified.name == #require(HTTPHeaderFieldName(rawValue:"Foo")))
    #expect(try unspecified.value == #require(HTTPHeaderFieldValue(rawValue:"Bar")))
  }
}
#else
import XCTest

final class AnyHTTPHeaderFieldDelegateTests: XCTestCase {
  func test_initializer() {
    let any1 = _AnyHTTPHeaderFieldDelegate(HTTPETagHeaderFieldDelegate(HTTPETag("*")!))
    XCTAssertEqual(any1.type, .single)
    XCTAssertEqual(any1.name, .eTag)
    XCTAssertEqual(any1.value, HTTPHeaderFieldValue(rawValue:"*")!)
    
    
    var any2 = _AnyHTTPHeaderFieldDelegate(IfMatchHTTPHeaderFieldDelegate(try! HTTPETagList("\"A\"")))
    any2.append(HTTPETag("\"B\"")!)
    XCTAssertEqual(any2.type, .appendable)
    XCTAssertEqual(any2.name, .ifMatch)
    XCTAssertEqual(any2.value, HTTPHeaderFieldValue(rawValue:"\"A\", \"B\"")!)
    
    let unspecified = _AnyHTTPHeaderFieldDelegate(name: HTTPHeaderFieldName(rawValue:"Foo")!,
                                                  value: HTTPHeaderFieldValue(rawValue:"Bar")!)
    XCTAssertEqual(unspecified.type, .single)
    XCTAssertEqual(unspecified.name, HTTPHeaderFieldName(rawValue:"Foo")!)
    XCTAssertEqual(unspecified.value, HTTPHeaderFieldValue(rawValue:"Bar")!)
  }
}
#endif
