/* *************************************************************************************************
 HeaderFieldNameTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import XCTest
@testable import HTTP

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

final class HeaderFieldNameTests: XCTestCase {
  func test_caseInsensitivity() {
    let name = "My-Special-Original-HTTP-Header-Field-Name"
    let fieldName1 = HeaderFieldName(rawValue: name._randomCased())!
    let fieldName2 = HeaderFieldName(rawValue: name._randomCased())!
    XCTAssertEqual(fieldName1, fieldName2, "\(fieldName1.rawValue) vs \(fieldName2.rawValue)")
    XCTAssertEqual(fieldName1.hashValue, fieldName2.hashValue, "Hash Values of: \(fieldName1.rawValue) vs \(fieldName2.rawValue)")
    
    let dictionary: [HeaderFieldName: Int] = [fieldName1: 1]
    XCTAssertEqual(dictionary[fieldName2], 1)
  }
}
