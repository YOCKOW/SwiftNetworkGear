/* *************************************************************************************************
 TokenTests.swift
   © 2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@testable import NetworkGear
import Testing

@Suite final class TokenTests {
  @Test func test_split() throws {
    let parameters_string = "A=B; C=\"D\""
    let parameters_tokens = try #require(parameters_string._tokens)
    #expect(parameters_tokens.count == 7)

    #expect(parameters_tokens[0] is _Token._RawString)
    #expect(parameters_tokens[0]._string == "A")

    #expect(parameters_tokens[1] is _Token._Separator)
    #expect(parameters_tokens[1]._string == "=")

    #expect(parameters_tokens[2] is _Token._RawString)
    #expect(parameters_tokens[2]._string == "B")

    #expect(parameters_tokens[3] is _Token._Separator)
    #expect(parameters_tokens[3]._string == ";")

    #expect(parameters_tokens[4] is _Token._RawString)
    #expect(parameters_tokens[4]._string == "C")

    #expect(parameters_tokens[5] is _Token._Separator)
    #expect(parameters_tokens[5]._string == "=")

    #expect(parameters_tokens[6] is _Token._QuotedString)
    #expect(parameters_tokens[6]._string == "D")

    let invalid_string = "A=\"B" // not closed
    #expect(invalid_string._tokens == nil)
  }

  @Test func test_dictionary() throws {
    let source_string = "; key0 = \"value0\" ;; key1 ; key2=value2 "
    let tokens = source_string._tokens!
    let dictionary = try #require(Dictionary<String,String>(_tokens:tokens))
    #expect(dictionary["key0"] == "value0")
    #expect(dictionary["key1"] == "")
    #expect(dictionary["key2"] == "value2")
  }
}
