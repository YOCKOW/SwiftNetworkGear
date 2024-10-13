/* *************************************************************************************************
 HTTPHeaderFieldNameTests.swift
   © 2019,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

extension String {
  func _randomCased() -> String {
    var result: String = ""
    for character in self {
      let uppercase: Bool = .random()
      result.append(uppercase ? character.uppercased() : character.lowercased())
    }
    return result
  }
}

#if swift(>=6) && canImport(Testing)
import Testing

@Suite struct HTTPHeaderFieldNameTests {
  @Test func test_caseInsensitivity() {
    let name = "My-Special-Original-HTTP-Header-Field-Name"
    let fieldName1 = HTTPHeaderFieldName(rawValue: name._randomCased())!
    let fieldName2 = HTTPHeaderFieldName(rawValue: name._randomCased())!
    #expect(fieldName1 == fieldName2, "\(fieldName1.rawValue) vs \(fieldName2.rawValue)")
    #expect(fieldName1.hashValue == fieldName2.hashValue, "Hash Values of: \(fieldName1.rawValue) vs \(fieldName2.rawValue)")

    let dictionary: [HTTPHeaderFieldName: Int] = [fieldName1: 1]
    #expect(dictionary[fieldName2] == 1)
  }
}
#else
import XCTest

final class HTTPHeaderFieldNameTests: XCTestCase {
  func test_caseInsensitivity() {
    let name = "My-Special-Original-HTTP-Header-Field-Name"
    let fieldName1 = HTTPHeaderFieldName(rawValue: name._randomCased())!
    let fieldName2 = HTTPHeaderFieldName(rawValue: name._randomCased())!
    XCTAssertEqual(fieldName1, fieldName2, "\(fieldName1.rawValue) vs \(fieldName2.rawValue)")
    XCTAssertEqual(fieldName1.hashValue, fieldName2.hashValue, "Hash Values of: \(fieldName1.rawValue) vs \(fieldName2.rawValue)")
    
    let dictionary: [HTTPHeaderFieldName: Int] = [fieldName1: 1]
    XCTAssertEqual(dictionary[fieldName2], 1)
  }
}
#endif
