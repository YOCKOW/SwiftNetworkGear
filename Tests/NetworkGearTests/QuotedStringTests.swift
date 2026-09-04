/* *************************************************************************************************
 QuotedStringTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite final class QuotedStringTests {
  @Test func test_quote() {
    #expect("ABC\\DEF"._quotedString(for: .http) == "\"ABC\\\\DEF\"")
    #expect("ABC\\DEF"._quotedString(for: .mime) == "\"ABC\\\\DEF\"")
    #expect("あ"._quotedString(for: .http) == nil)
    #expect("あ"._quotedString(for: .mime) == nil)
  }

  @Test func test_unquote() {
    #expect("\"ABC\\\\DEF\""._unquotedString(for: .http) == "ABC\\DEF")
    #expect("\"ABC\\\\DEF\""._unquotedString(for: .mime) == "ABC\\DEF")
    #expect("\"NOTCLOSED"._unquotedString(for: .http) == nil)
    #expect("\"NOTCLOSED"._unquotedString(for: .mime) == nil)
  }

  @Test func test_appending() throws {
    let q1 = try #require(HTTPQuotedString(quoting: ##"A"B"C"##))
    let q2 = try #require(HTTPQuotedString(quoting: ##""D"E"F"##))
    let appended = q1.appending(q2)
    #expect(appended.quotedString == ##""A\"B\"C\"D\"E\"F""##)
    #expect(appended.content == ##"A"B"C"D"E"F"##)
  }

  @Test func test_divide() throws {
    let content = #"A\B"C\D"E"#
    let quotedRawValue = try #require(content._quotedString(for: .http))

    enum __Source: Equatable {
      case content
      case quotedString
    }
    var source: __Source = .content
    var quotedString: HTTPQuotedString {
      get {
        switch source {
        case .content:
          return HTTPQuotedString(content: content)
        case .quotedString:
          return HTTPQuotedString(quotedString: quotedRawValue)
        }
      }
    }

    func __assert(
      divideCount count: Int,
      expected: (firstPart: String, secondPart: String?),
      _ comment: @autoclosure () -> Comment? = nil,
      sourceLocation: SourceLocation = #_sourceLocation
    ) {
      let divided = quotedString.divide(whereFirstPartMaxUTF8Count: count)
      #expect(
        divided.0.quotedString.utf8.count <= count,
        Comment(rawValue: "[Count (\(source))] " + (comment()?.rawValue ?? "")),
        sourceLocation: sourceLocation
      )
      #expect(
        divided.0.content == expected.firstPart,
        Comment(rawValue: "[First Part (\(source))] " + (comment()?.rawValue ?? "")),
        sourceLocation: sourceLocation
      )
      #expect(
        divided.1?.content == expected.secondPart,
        Comment(rawValue: "[Second Part (\(source))] " + (comment()?.rawValue ?? "")),
        sourceLocation: sourceLocation
      )
    }

    for switcher in [.content, .quotedString] as Array<__Source> {
      source = switcher
      __assert(divideCount: 99, expected: (quotedString.content, nil))
      __assert(divideCount: 15, expected: (quotedString.content, nil))
      __assert(divideCount: 14, expected: (#"A\B"C\D""#, "E"))
      __assert(divideCount: 13, expected: (#"A\B"C\D"#, #""E"#))
      __assert(divideCount: 12, expected: (#"A\B"C\D"#, #""E"#))
      __assert(divideCount: 11, expected: (#"A\B"C\"#, #"D"E"#))
      __assert(divideCount: 10, expected: (#"A\B"C"#, #"\D"E"#))
      __assert(divideCount:  9, expected: (#"A\B"C"#, #"\D"E"#))
      __assert(divideCount:  8, expected: (#"A\B""#, #"C\D"E"#))
      __assert(divideCount:  7, expected: (#"A\B"#, #""C\D"E"#))
      __assert(divideCount:  6, expected: (#"A\B"#, #""C\D"E"#))
      __assert(divideCount:  5, expected: (#"A\"#, #"B"C\D"E"#))
      __assert(divideCount:  4, expected: (#"A"#, #"\B"C\D"E"#))
    }
  }
}
