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
    JSON_API: do {
      let string = "application/vnd.api+json"
      let type = try #require(MIMEType(string))

      #expect(type.type == .application)
      #expect(type.tree == .vnd)
      #expect(type.subtype == "api")
      #expect(type.suffix == .json)

      #expect(type.description == string)
    }

    XHTML_UTF8: do {
      let string = "application/xhtml+xml; charset=UTF-8; myparameter=myvalue"
      let type = try #require(MIMEType(string))

      #expect(type.type == .application)
      #expect(type.tree == nil)
      #expect(type.subtype == "xhtml")
      #expect(type.suffix == .xml)
      #expect(type.parameters?["charset"] == "UTF-8")
      #expect(type.parameters?["myparameter"] == "myvalue")

      #expect(type._description(sortParameters: true) == string)
    }

    JUST_FOR_TEST: do {
      let string = #"example/x.foo.bar.baz+gzip; my-name=my-value; with-spaces="a b c"; "#
      let type = try #require(MIMEType(string))

      #expect(type.type == .example)
      #expect(type.tree == .x)
      #expect(type.subtype == "foo.bar.baz")
      #expect(type.suffix == .gzip)
      #expect(type.parameters?["my-name"] == "my-value")
      #expect(type.parameters?["with-spaces"] == "a b c")

      #expect(
        type._description(sortParameters: true) ==
        #"example/x.foo.bar.baz+gzip; my-name=my-value; with-spaces="a b c""#
      )
    }
  }

  @Test func test_pathExtensions() {
    let txt_ext: MIMEType.PathExtension = .txt
    let text_mime_type = MIMEType(pathExtension:txt_ext)

    #expect(text_mime_type == MIMEType(type:.text, subtype:"plain"))
    #expect(text_mime_type?.possiblePathExtensions?.contains(txt_ext) == true)
  }
}
