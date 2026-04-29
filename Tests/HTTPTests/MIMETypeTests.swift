/* *************************************************************************************************
 MIMETypeTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
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
