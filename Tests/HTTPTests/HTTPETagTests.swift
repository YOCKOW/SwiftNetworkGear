/* *************************************************************************************************
 HTTPETagTests.swift
   © 2017-2018,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct HTTPETagTests {
  @Test func test_initialization() {
    #expect(HTTPETag("unquoted") == nil)
    #expect(HTTPETag("\"STRONG\"") == .strong("STRONG"))
    #expect(HTTPETag("W/\"WEAK\"") == .weak("WEAK"))
    #expect(HTTPETag("*") == .any)
  }

  @Test func test_comparison() {
    let strong = HTTPETag("\"HTTPETag\"")!
    let weak = HTTPETag("W/\"HTTPETag\"")!

    #expect(strong =~ weak)
    #expect(strong != weak)
  }

  @Test func test_list() throws {
    #expect(HTTPETagList(string: "*") == .any)

    let list = try #require(HTTPETagList(string: #""A", "B", W/"C",  "D" "#))
    guard case .list(let array) = list else {
      Issue.record("Unexpected Error")
      return
    }
    #expect(array[0] == .strong("A"))
    #expect(array[1] == .strong("B"))
    #expect(array[2] == .weak("C"))
    #expect(array[3] == .strong("D"))

    #expect(list.contains(.strong("A")))
    #expect(list.contains(.weak("C")))
    #expect(list.contains(.strong("C"), weakComparison: true))
    #expect(list.contains(.weak("D"), weakComparison: true))
  }

  @available(*, deprecated)
  @Test func test_list_deprecated() {
    let trial = { (string:String, expectedError:HTTPETagParseError) -> Void in
      do {
        _ = try HTTPETagList(string)
      } catch {
        guard case let parseError as HTTPETagParseError = error else {
          Issue.record("Unexpected Error was thrown.")
          return
        }
        #expect(expectedError == parseError, "Expected Error: \(expectedError); Actual Error: \(parseError)")
      }
    }

    trial(", \"A\"", .extraComma)
    trial("\"A\", , \"B\"", .extraComma)

    trial("?", .unexpectedCharacter)
    trial("W-\"A\"", .unexpectedCharacter)
    trial("W/'A'", .unexpectedCharacter)

    trial("\"", .unterminatedTag)
    trial("W/\"ABCDEFGHIJKLMN", .unterminatedTag)
    trial("W/\"ABCDEFGHIJKLMN\\\"", .unterminatedTag)

    do {
      let list = try HTTPETagList("\"A\", \"B\", W/\"C\",  \"D\" ")
      guard case .list(let array) = list else {
        Issue.record("Unexpected Error")
        return
      }
      #expect(array[0] == .strong("A"))
      #expect(array[1] == .strong("B"))
      #expect(array[2] == .weak("C"))
      #expect(array[3] == .strong("D"))

      #expect(list.contains(.strong("A")))
      #expect(list.contains(.weak("C")))
      #expect(list.contains(.strong("C"), weakComparison:true))
      #expect(list.contains(.weak("D"), weakComparison:true))
    } catch {
      Issue.record("Unexpected Error: \(error)")
    }
  }

  @Test public func test_headerField() {
    let eTag1 = HTTPETag("\"SomeETag\"")!
    let eTag2 = HTTPETag("W/\"SomeWeakETag\"")!

    var eTagField = HTTPETagHeaderFieldDelegate(eTag1)
    #expect(type(of:eTagField).name == .eTag)
    #expect(eTagField.value.rawValue == eTag1.description)

    eTagField.source = eTag2
    #expect(eTagField.value.rawValue == eTag2.description)

    #expect(type(of:eTagField).type == .single)

    var ifMatchField = IfMatchHTTPHeaderFieldDelegate(.list([eTag1]))
    ifMatchField.append(eTag2)
    #expect(type(of:ifMatchField).name == .ifMatch)
    #expect(ifMatchField.value.rawValue == "\(eTag1.description), \(eTag2.description)")
    #expect(type(of:ifMatchField).type == .appendable)

    var ifNoneMatchField = IfMatchHTTPHeaderFieldDelegate(.list([eTag1]))
    ifNoneMatchField.append(eTag2)
    #expect(type(of:ifNoneMatchField).name == .ifMatch)
    #expect(ifNoneMatchField.value.rawValue == "\(eTag1.description), \(eTag2.description)")
    #expect(type(of:ifNoneMatchField).type == .appendable)
  }
}
