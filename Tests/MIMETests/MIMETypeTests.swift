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
        #"example/x.foo.bar.baz+gzip; my-name=my-value; with-spaces="a\ b\ c""#
      )
    }
  }

  @Test func test_pathExtensions() {
    let txt_ext: MIMEType.PathExtension = .txt
    let text_mime_type = MIMEType(pathExtension:txt_ext)

    #expect(text_mime_type == MIMEType(type:.text, subtype:"plain"))
    #expect(text_mime_type?.possiblePathExtensions?.contains(txt_ext) == true)
  }

  @Test func test_boundary() throws {
    let boundary = try #require(MultipartBoundary(rawValue: "my-border     \u{0D}\u{0A}"))
    #expect(boundary.rawValue == "my-border")

    let multipartFormData = MIMEType.multipartFormData(boundary: .random())
    let formDataBoundary = try #require(multipartFormData.boundary)
    #expect(formDataBoundary.rawValue.hasSuffix("--SwiftNetworkGear"))
    #expect(MultipartBoundary(rawValue: formDataBoundary.rawValue) == formDataBoundary)
  }

  @Test(arguments: Array<(generated: MIMEType, expected: MIMEType)>([
    (.apng, .init(type: .image, subtype: "apng")),
    (.avif, .init(type: .image, subtype: "avif")),
    (.css, .init(type: .text, subtype: "css")),
    (.css(charset: "UTF-8"), .init(type: .text, subtype: "css", parameters: [.charset: "UTF-8"])),
    (.css(encoding: .japaneseEUC), .css(charset: "euc-jp")),
    (.gif, .init(type: .image, subtype: "gif")),
    (.html, .init(type: .text, subtype: "html")),
    (.html(charset: "US-ASCII"), .init(type: .text, subtype: "html", parameters: [.charset: "US-ASCII"])),
    (.html(encoding: .ascii), .html(charset: "us-ascii")),
    (.javascript, .init(type: .text, subtype: "javascript")),
    (.javascript(charset: "utf-8"), .init(type: .text, subtype: "javascript", parameters: [.charset: "utf-8"])),
    (.javascript(encoding: .utf8), .javascript(charset: "utf-8")),
    (.jpeg, .init(type: .image, subtype: "jpeg")),
    (.json, .init(type: .application, subtype: "json")),
    (.json(charset: "utf-8"), .init(type: .application, subtype: "json", parameters: [.charset: "utf-8"])),
    (.json(encoding: .utf8), .json(charset: "utf-8")),
    (
      .multipartByteRanges(boundary: try #require(MultipartBoundary(rawValue: "boundary"))),
      .init(type: .multipart, subtype: "byteranges", parameters: [.boundary: "boundary"])
    ),
    (
      .multipartFormData(boundary: try #require(MultipartBoundary(rawValue: "boundary"))),
      .init(type: .multipart, subtype: "form-data", parameters: [.boundary: "boundary"])
    ),
    (.octetStream, .init(type: .application, subtype: .octetStream)),
    (.plainText, .init(type: .text, subtype: "plain")),
    (.plainText(charset: "utf-8"), .init(type: .text, subtype: "plain", parameters: [.charset: "utf-8"])),
    (.plainText(encoding: .utf8), .plainText(charset: "utf-8")),
    (.png, .init(type: .image, subtype: "png")),
    (.svg, .init(type: .image, subtype: "svg", suffix: .xml)),
    (.webp, .init(type: .image, subtype: "webp")),
    (.wwwFormURLEncoded, .init(type: .application, subtype: .wwwFormURLEncoded)),
  ]))
  func test_staticProperties(_ pair: (generated: MIMEType, expected: MIMEType)) {
    #expect(pair.generated._isEqual(to: pair.expected, ignoreCaseOfParameterValues: true))
  }
}
