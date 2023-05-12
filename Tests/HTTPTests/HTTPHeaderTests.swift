/* *************************************************************************************************
 HTTPHeaderTests.swift
   © 2018,2023 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import XCTest
@testable import NetworkGear

final class HTTPHeaderTests: XCTestCase {
  func test_appending() {
    var header = HTTPHeader([])
    
    let strongETag: HTTPETag = .strong("STRONG")
    let weakETag: HTTPETag = .weak("WEAK")
    let strongETag2: HTTPETag = .strong("STRONG2")
    
    header.insert(.ifNoneMatch(.list([strongETag])))
    XCTAssertEqual(header.count, 1)
    
    header.insert(.ifNoneMatch(.list([weakETag])))
    XCTAssertEqual(header.count, 1) // "if-none-match" is not duplicable, but appendable
    
    XCTAssertEqual(header[.ifNoneMatch][0].source as! HTTPETagList, HTTPETagList.list([strongETag, weakETag]))
    
    header.insert(.ifNoneMatch(.list([strongETag2])), removingExistingFields:true)
    XCTAssertEqual(header.count, 1)
    XCTAssertEqual(header[.ifNoneMatch][0].source as! HTTPETagList, HTTPETagList.list([strongETag2]))
    
    header.removeFields(forName:.ifNoneMatch)
    XCTAssertEqual(header.count, 0)
  }
  
  func test_asSequence() {
    let header: HTTPHeader = [
      "Set-Cookie": "name1=value1; Domain=Example.com; Path=/",
      "X-Name1": "Value1",
      "X-Name2": "Value2",
      "Set-Cookie": "name2=value2; Domain=Example.com; Path=/"
    ]
    
    XCTAssertEqual(Array<HTTPHeaderField>(header).count, 4)
    XCTAssertEqual(header.filter({ $0.name == .setCookie }).count, 2)
    XCTAssertEqual(header.filter({ $0.name == "X-Name1" }).count, 1)
    XCTAssertEqual(header.filter({ $0.name == "X-Name2" }).count, 1)
  }

  func test_asCodable() throws {
    let json = """
    {
      "Cache-Control" : "public",
      "Content-Type" : "text/plain",
      "X-Custom-Field" : "Hoge"
    }
    """

    let header = try JSONDecoder().decode(HTTPHeader.self, from: Data(json.utf8))
    let fields = header.sorted(by: { $0.name.rawValue < $1.name.rawValue })
    XCTAssertEqual(fields.count, 3)
    XCTAssertEqual(fields.first?.name, "Cache-Control")
    XCTAssertEqual(fields.dropFirst().first?.source as? MIMEType, MIMEType(pathExtension: .txt))
    XCTAssertEqual(fields.last?.value, "Hoge")

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
    let encoded = try XCTUnwrap(String(data: try  encoder.encode(header), encoding: .utf8))
    XCTAssertEqual(encoded, json)
  }
}
