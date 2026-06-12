/* *************************************************************************************************
 StringParserTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

struct DigitParser<Input: StringProtocol>: StringParser, _UTF8Parser {
  typealias Output = Int
  let input: Input
  let utf8: Input.UTF8View
  init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }
  mutating func parse() -> (output: Int, endIndex: Input.Index)? {
    var index = self.utf8.startIndex
    guard let parsedResult = self.parseString(from: &index, while: \._isDigit) else {
      return nil
    }
    return (Int(String(input[..<parsedResult.endIndex]))!, parsedResult.endIndex)
  }
}

struct HiraganaParser<Input: StringProtocol>: StringParser {
  typealias Output = Input.SubSequence
  let string: Input
  init(input: Input) {
    self.string = input
  }
  mutating func parse() -> (output: Input.SubSequence, endIndex: Input.Index)? {
    let scalars = string.unicodeScalars
    var index = scalars.startIndex
    while index < scalars.endIndex {
      let scalar = scalars[index]
      guard (0x3040...0x309F as ClosedRange<UInt32>).contains(scalar.value) else {
        break
      }
      scalars.formIndex(after: &index)
    }
    guard index > scalars.startIndex else {
      return nil
    }
    return (output: string[..<index], endIndex: index)
  }
}

typealias _DigitHiraganaParser<Input> = CombinedParser<Input, DigitParser<Input>, HiraganaParser<Input.SubSequence>> where Input: StringProtocol

@Suite struct StringParserTests {
  @Test func test_LinearWhitespace() throws {
    let CR = "\u{0D}"
    let LF = "\u{0A}"
    let CRLF = CR + LF
    let SP = "\u{20}"
    let HTAB = "\u{09}"

    #expect(LinearWhitespaceParser.parse("ABC  ").isNil)
    #expect(LinearWhitespaceParser.parse(LF).isNil)
    #expect(LinearWhitespaceParser.parse(CR).isNil)
    #expect(LinearWhitespaceParser.parse(LF + CR).isNil)
    #expect(LinearWhitespaceParser.parse(CRLF).isNil)
    #expect(LinearWhitespaceParser.parse(CRLF + "ABC").isNil)

    do {
      let string = SP + HTAB + SP + HTAB
      let result = try #require(LinearWhitespaceParser.parse(string))
      #expect(result.output == string)
      #expect(result.endIndex == string.endIndex)
    }

    do {
      let string = CRLF + HTAB + SP
      let result = try #require(LinearWhitespaceParser.parse(string))
      #expect(result.output == string)
      #expect(result.endIndex == string.endIndex)
    }

    do {
      let string = SP + HTAB + CRLF + HTAB + SP
      let result = try #require(LinearWhitespaceParser.parse(string))
      #expect(result.output == string)
      #expect(result.endIndex == string.endIndex)
    }

    do {
      let lwsp = HTAB + SP + CRLF + SP + HTAB
      let string = lwsp + "ABC"
      let result = try #require(LinearWhitespaceParser.parse(string))
      #expect(result.output == lwsp)
      #expect(string[result.endIndex...] == "ABC")
    }
  }

  @Test func test_CombinedParser() {
    #expect(_DigitHiraganaParser<String>.parse("0123").isNil)
    #expect(_DigitHiraganaParser<String>.parse("0123ABC").isNil)
    #expect(_DigitHiraganaParser<String>.parse("ABC").isNil)
    #expect(_DigitHiraganaParser<String>.parse("あいうえお").isNil)
    #expect(!_DigitHiraganaParser<String>.parse("0123あいうえお").isNil)
    #expect(!_DigitHiraganaParser<String>.parse("0123あいうえおABC").isNil)
  }

  @Test func test_RepetitionParser() throws {
    let string = "123あいうえお456かきくけこ"
    let result = try #require(RepetitionParser<String, _DigitHiraganaParser<Substring>>.parse(string))
    #expect(result.output.count == 2)
    #expect(try #require(result.output.first).firstOutput == 123)
    #expect(try #require(result.output.first).secondOutput == "あいうえお")
    #expect(try #require(result.output.last).firstOutput == 456)
    #expect(try #require(result.output.last).secondOutput == "かきくけこ")
    #expect(result.endIndex == string.endIndex)

    let limitedParser = RepetitionParser<String, _DigitHiraganaParser<Substring>>(input: string)
    limitedParser.maxCount = 1
    // Workaround for https://github.com/swiftlang/swift-testing/issues/1360
    let limitedResult = try #require(limitedParser.parse() ?? nil)
    #expect(limitedResult.output.count == 1)
    #expect(try #require(limitedResult.output.first).firstOutput == 123)
    #expect(try #require(limitedResult.output.first).secondOutput == "あいうえお")
    #expect(limitedResult.endIndex != string.endIndex)
  }
}
