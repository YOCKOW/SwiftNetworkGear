/* *************************************************************************************************
 StringParserTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

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

private let CR = "\u{0D}"
private let LF = "\u{0A}"
private let CRLF = CR + LF
private let SP = "\u{20}"
private let HTAB = "\u{09}"

@Suite struct StringParserTests {
  @Test func test_prefixParser() throws {
    struct __Parser: _InputAccessibleParser {
      typealias Input = String
      typealias Output = Substring
      let input: String
      init(input: String) {
        self.input = input
      }
      mutating func parse() -> (output: Substring, endIndex: String.Index)? {
        var index = input.startIndex
        guard let prefix = self.parseASCIICaseInsensitivePrefix("prefix", from: &index) else {
          return nil
        }
        return (prefix, index)
      }
    }

    #expect(__Parser.parse("").isNil)
    #expect(__Parser.parse("foo-bar-baz").isNil)
    #expect(!__Parser.parse("prefix").isNil)

    let string = "PREFIX-SUFFIX"
    let result = try #require(__Parser.parse(string))
    #expect(result.output == "PREFIX")
    #expect(string[result.endIndex...] == "-SUFFIX")
  }

  @Test func test_LinearWhitespace() throws {
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

    do {
      let repeated = SP + CRLF + SP + CRLF + SP
      let result = try #require(LinearWhitespaceParser.parse(repeated))
      #expect(result.output == repeated)
      #expect(result.endIndex == repeated.endIndex)
    }
  }

  @Test func test_FoldingWhitespaceParser() throws {
    #expect(FoldingWhitespaceParser.parse("ABC  ").isNil)
    #expect(FoldingWhitespaceParser.parse(LF).isNil)
    #expect(FoldingWhitespaceParser.parse(CR).isNil)
    #expect(FoldingWhitespaceParser.parse(LF + CR).isNil)
    #expect(FoldingWhitespaceParser.parse(CRLF).isNil)
    #expect(FoldingWhitespaceParser.parse(CRLF + "ABC").isNil)

    do {
      let string = SP + HTAB + SP + HTAB
      let result = try #require(FoldingWhitespaceParser.parse(string))
      #expect(result.output == string)
      #expect(result.endIndex == string.endIndex)
    }

    do {
      let string = CRLF + HTAB + SP
      let result = try #require(FoldingWhitespaceParser.parse(string))
      #expect(result.output == string)
      #expect(result.endIndex == string.endIndex)
    }

    do {
      let string = SP + HTAB + CRLF + HTAB + SP
      let result = try #require(FoldingWhitespaceParser.parse(string))
      #expect(result.output == string)
      #expect(result.endIndex == string.endIndex)
    }

    do {
      let lwsp = HTAB + SP + CRLF + SP + HTAB
      let string = lwsp + "ABC"
      let result = try #require(FoldingWhitespaceParser.parse(string))
      #expect(result.output == lwsp)
      #expect(string[result.endIndex...] == "ABC")
    }

    do {
      let fws1 = SP + CRLF + HTAB
      let fws2 = HTAB + CRLF + SP
      let string = fws1 + fws2
      let result = try #require(FoldingWhitespaceParser.parse(string))
      #expect(result.output == fws1 + HTAB)
      #expect(string[result.endIndex...] == CRLF + SP)
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

    var limitedParser = RepetitionParser<String, _DigitHiraganaParser<Substring>>(input: string)
    limitedParser.maxCount = 1
    // Workaround for https://github.com/swiftlang/swift-testing/issues/1360
    let limitedResult = try #require(limitedParser.parse() ?? nil)
    #expect(limitedResult.output.count == 1)
    #expect(try #require(limitedResult.output.first).firstOutput == 123)
    #expect(try #require(limitedResult.output.first).secondOutput == "あいうえお")
    #expect(limitedResult.endIndex != string.endIndex)
  }

  @Test func test_trimmingParser() throws {
    var parser = TrimmingParser<String, HiraganaParser<Substring>>(input: "   あいうえお    ")
    let hiragana = try #require(parser.parse()?.output)
    #expect(hiragana == "あいうえお")
  }
}
