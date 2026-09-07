/* *************************************************************************************************
 MIMEDateTimeParserTests.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGear
import Testing

@Suite struct MIMEDateTimeParserTests {
  @Test func parser() throws {
    let string = "Mon, 7 Sep 2026 17:08:09 +0900"

    var parser = MIMEDateTimeParser<String>(input: string)
    #expect(parser.allowObsoletedForms == false)

    let parsed = try #require(parser.parse()?.output)
    #expect(parsed.isValidDate)
    #expect(parsed.day == 7)
    #expect(parsed.month == 9)
    #expect(parsed.year == 2026)
    #expect(parsed.hour == 17)
    #expect(parsed.minute == 8)
    #expect(parsed.second == 9)
    #expect(parsed.timeZone?.secondsFromGMT() == 32400)

    parser.allowObsoletedForms = true
    #expect(parser.parse()?.output == parsed)
  }

  @Test func obsoletedParser() throws {
    let string = "(day of week)Mon(day), 7(th) Sep(tember) (20)26 08(hour):08(minute):09(second) GMT"
    var parser = MIMEDateTimeParser<String>(
      input: string,
      allowObsoletedForms: true
    )

    let parsed = try #require(parser.parse()?.output)
    #expect(parsed.isValidDate)
    #expect(parsed.day == 7)
    #expect(parsed.month == 9)
    #expect(parsed.year == 2026)
    #expect(parsed.hour == 8)
    #expect(parsed.minute == 8)
    #expect(parsed.second == 9)
    #expect(parsed.timeZone?.secondsFromGMT() == 0)
  }
}
