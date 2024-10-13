/* *************************************************************************************************
 MIMETypeTests.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class MIMETypeTests {
  @Test func test_parser() throws {
    let xhtml_type_utf8_string = "application/xhtml+xml; charset=UTF-8; myparameter=myvalue"
    let xhtml_type = try #require(MIMEType(xhtml_type_utf8_string))

    #expect(xhtml_type.type == .application)
    #expect(xhtml_type.tree == nil)
    #expect(xhtml_type.subtype == "xhtml")
    #expect(xhtml_type.suffix == .xml)
    #expect(xhtml_type.parameters?["charset"] == "UTF-8")
    #expect(xhtml_type.parameters?["myparameter"] == "myvalue")
  }

  @Test func test_pathExtensions() {
    let txt_ext: MIMEType.PathExtension = .txt
    let text_mime_type = MIMEType(pathExtension:txt_ext)

    #expect(text_mime_type == MIMEType(type:.text, subtype:"plain"))
    #expect(text_mime_type?.possiblePathExtensions?.contains(txt_ext) == true)
  }
}
#else
import XCTest

final class MIMETypeTests: XCTestCase {
  func test_parser() {
    let xhtml_type_utf8_string = "application/xhtml+xml; charset=UTF-8; myparameter=myvalue"
    let xhtml_type = MIMEType(xhtml_type_utf8_string)
    
    XCTAssertNotNil(xhtml_type)
    XCTAssertEqual(xhtml_type?.type, .application)
    XCTAssertEqual(xhtml_type?.tree, nil)
    XCTAssertEqual(xhtml_type?.subtype, "xhtml")
    XCTAssertEqual(xhtml_type?.suffix, .xml)
    XCTAssertEqual(xhtml_type?.parameters?["charset"], "UTF-8")
    XCTAssertEqual(xhtml_type?.parameters?["myparameter"], "myvalue")
  }
  
  func test_pathExtensions() {
    let txt_ext: MIMEType.PathExtension = .txt
    let text_mime_type = MIMEType(pathExtension:txt_ext)
    
    XCTAssertEqual(text_mime_type, MIMEType(type:.text, subtype:"plain"))
    XCTAssertEqual(text_mime_type?.possiblePathExtensions?.contains(txt_ext), true)
  }
}
#endif
