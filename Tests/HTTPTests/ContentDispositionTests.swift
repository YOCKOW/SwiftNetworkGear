/* *************************************************************************************************
 ContentDispositionTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct ContentDispositionTests {
  @Test func test_value() throws {
    #expect(ContentDispositionValue.attachment.rawValue == "attachment")
    #expect(
      ContentDispositionValue.dispositionType(
        try #require(ASCIICaseInsensitiveHTTPTokenString("hoge"))
      ).rawValue == "hoge"
    )
    #expect(ContentDispositionValue(rawValue: "INLINE") == .inline)
  }

  @Test func test_parser() {
    let attachment = ContentDisposition("attachment; filename=\"my-file.txt\"; filename*=UTF-8''%E7%A7%81%E3%81%AE%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt;")
    #expect(attachment.type == .attachment)
    #expect(attachment.parameterList?[.filename]?.content == "my-file.txt")
    #expect(attachment.parameterList?[extended: .filename]?.decodedValue == "私のファイル.txt")
    #expect(attachment.filename == "私のファイル.txt")

    let formData = ContentDisposition("form-data; name=\"field\"")
    #expect(formData.type == .formData)
    #expect(formData.parameterList?["name"]?.value == "field")
  }
}
