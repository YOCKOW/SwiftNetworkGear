/* *************************************************************************************************
 AnyHTTPHeaderFieldDelegateTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import NetworkGear

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



