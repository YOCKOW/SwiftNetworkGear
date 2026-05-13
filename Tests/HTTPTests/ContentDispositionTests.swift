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
    let attachment = ContentDisposition("attachment; filename=\"myfile.txt\"")
    #expect(attachment.value == .attachment)
    #expect(attachment.parameters?["filename"] == "myfile.txt")


    let formData = ContentDisposition("form-data; name=\"field\"")
    #expect(formData.value == .formData)
    #expect(formData.parameters?["name"] == "field")
  }
}
