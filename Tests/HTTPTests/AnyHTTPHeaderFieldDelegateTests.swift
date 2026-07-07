/* *************************************************************************************************
 AnyHTTPHeaderFieldDelegateTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import NetworkGear
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
