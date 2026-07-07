/* *************************************************************************************************
 HTTPHeaderFieldNameTests.swift
   © 2019,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

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
