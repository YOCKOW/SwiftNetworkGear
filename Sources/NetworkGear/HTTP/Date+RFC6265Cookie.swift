/* *************************************************************************************************
 Date+RFC6265Cookie.swift
   © 2017-2018,2023,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

// MARK: - Day of the week

/// Day of the week.
internal enum Weekday: Sendable, Equatable, Hashable {
  case sunday
  case monday
  case tuesday
  case wednesday
  case thursday
  case friday
  case saturday
}

internal struct WeekdayParser<Input>: StringParser,
                                      _InputAccessibleParser where Input: StringProtocol {
  typealias Output = Weekday
  let input: Input
  init(input: Input) {
    self.input = input
  }

  func parse() -> (output: Weekday, endIndex: Input.Index)? {
    var index = input.startIndex

    func __parseDayIfPossible()  {
      _ = self.parseASCIICaseInsensitivePrefix("day", from: &index)
    }

    if let _ = self.parseASCIICaseInsensitivePrefix("sun", from: &index) {
      __parseDayIfPossible()
      return (.sunday, index)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("mon", from: &index) {
      __parseDayIfPossible()
      return (.monday, index)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("tue", from: &index) {
      if let _ = self.parseASCIICaseInsensitivePrefix("s", from: &index) {
        __parseDayIfPossible()
      }
      return (.tuesday, index)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("wed", from: &index) {
      if let _ = self.parseASCIICaseInsensitivePrefix("nes", from: &index) {
        __parseDayIfPossible()
      }
      return (.wednesday, index)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("thu", from: &index) {
      // Accept "Thur" too.
      if let _ = self.parseASCIICaseInsensitivePrefix("r", from: &index),
         let _ = self.parseASCIICaseInsensitivePrefix("s", from: &index) {
        __parseDayIfPossible()
      }
      return (.thursday, index)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("fri", from: &index) {
      __parseDayIfPossible()
      return (.friday, index)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("sat", from: &index) {
      _ = self.parseASCIICaseInsensitivePrefix("urday", from: &index)
      return (.saturday, index)
    } else {
      return nil
    }
  }
}

extension Weekday: _InitializableWithParser {
  public init?<S>(_ string: S) where S: StringProtocol {
    self.init(string, parser: WeekdayParser<S>.self)
  }
}

// MARK: - Month

internal enum Month: Int {
  case january = 1
  case february = 2
  case march = 3
  case april = 4
  case may = 5
  case june = 6
  case july = 7
  case august = 8
  case september = 9
  case october = 10
  case november = 11
  case december = 12
}

internal struct MonthNameParser<Input>: StringParser, _InputAccessibleParser where Input: StringProtocol {
  typealias Output = Month

  let input: Input

  init(input: Input) {
    self.input = input
  }

  func parse() -> (output: Month, endIndex: Input.Index)? {
    var index = input.startIndex

    func __parse(prefix: String, suffix: String) -> Bool {
      guard let _ = self.parseASCIICaseInsensitivePrefix(prefix, from: &index) else {
        return false
      }
      _ = self.parseASCIICaseInsensitivePrefix(suffix, from: &index)
      return true
    }

    if __parse(prefix: "jan", suffix: "uary") {
      return (.january, index)
    } else if __parse(prefix: "feb", suffix: "ruary") {
      return (.february, index)
    } else if __parse(prefix: "mar", suffix: "ch") {
      return (.march, index)
    } else if __parse(prefix: "apr", suffix: "il") {
      return (.april, index)
    } else if __parse(prefix: "may", suffix: "") {
      return (.may, index)
    } else if __parse(prefix: "jun", suffix: "e") {
      return (.june, index)
    } else if __parse(prefix: "jul", suffix: "y") {
      return (.july, index)
    } else if __parse(prefix: "aug", suffix: "ust") {
      return (.august, index)
    }  else if __parse(prefix: "sep", suffix: "tember") {
      return (.september, index)
    } else if __parse(prefix: "oct", suffix: "ober") {
      return (.october, index)
    } else if __parse(prefix: "nov", suffix: "ember") {
      return (.november, index)
    } else if __parse(prefix: "dec", suffix: "ember") {
      return (.december, index)
    }

    return nil
  }
}

extension Month: _InitializableWithParser {
  init?<S>(_ string: S) where S: StringProtocol {
    self.init(string, parser: MonthNameParser<S>.self)
  }
}

// MARK: - dd MMM yyyy

private extension Int {
  var _normalizedYear: Int {
    switch self {
    case 0...69: return self + 2000
    case 79...99: return self + 1900
    default: return self
    }
  }
}

internal struct DayMonthYearParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  typealias Output = (day: Int, month: Month, year: Int)

  struct Configuration {
    let separator: (Unicode.UTF8.CodeUnit) -> Bool

    init(separator: @escaping (Unicode.UTF8.CodeUnit) -> Bool) {
      self.separator = separator
    }
  }

  let input: Input
  let utf8: Input.UTF8View
  let configuration: Configuration?
  var separator: (Unicode.UTF8.CodeUnit) -> Bool { configuration?.separator ?? \._isHTTPWhitespace }

  init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  init(input: Input, separator: @escaping (Unicode.UTF8.CodeUnit) -> Bool) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = Configuration(separator: separator)
  }

  func parse() -> (output: Output, endIndex: Input.Index)? {
    var index = utf8.startIndex

    guard let day = self.parseInt(
      from: &index,
      minNumberOfDigits: 2,
      maxNumberOfDigits: 2,
      radix: 10
    ) else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: separator) else {
      return nil
    }

    guard let month = MonthNameParser.parse(input, from: &index) else {
      return nil
    }

    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: separator) else {
      return nil
    }

    guard let year = self.parseInt(
      from: &index,
      minNumberOfDigits: 2,
      maxNumberOfDigits: 4,
      radix: 10
    ) else {
      return nil
    }

    let result: Output = (day: day, month: month, year: year._normalizedYear)
    return (result, index)
  }

  static func parse(
    _ input: Input,
    from index: inout Input.Index,
    separator: @escaping (Unicode.UTF8.CodeUnit) -> Bool
  ) -> Output? {
    let parser = DayMonthYearParser<Input.SubSequence>(input: input[index...], separator: separator)
    guard let (output, endIndex) = parser.parse() else {
      return nil
    }
    index = endIndex
    return output
  }
}


// MARK: - HH:mm:ss

internal struct HourMinuteSecondParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  typealias Output = (hour: Int, minute: Int, second: Int)
  
  struct Configuration {
    let minNumberOfDigits: Int
    let maxNumberOfDigits: Int
    let separator: (Unicode.UTF8.CodeUnit) -> Bool
    
    init(
      minNumberOfDigits: Int,
      maxNumberOfDigits: Int,
      separator: @escaping (Unicode.UTF8.CodeUnit) -> Bool
    ) {
      self.minNumberOfDigits = minNumberOfDigits
      self.maxNumberOfDigits = maxNumberOfDigits
      self.separator = separator
    }
  }

  let input: Input
  let utf8: Input.UTF8View
  let configuration: Configuration?

  var minNumberOfDigits: Int { configuration?.minNumberOfDigits ?? 2 }
  var maxNumberOfDigits: Int { configuration?.maxNumberOfDigits ?? 2 }
  var separator: (Unicode.UTF8.CodeUnit) -> Bool { configuration?.separator ?? \._isColon }

  init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  func parse() -> (output: Output, endIndex: Input.Index)? {
    var index = utf8.startIndex

    let minNumberOfDigits = self.minNumberOfDigits
    let maxNumberOfDigits = self.maxNumberOfDigits
    let separator = self.separator

    func __parseDigits() -> Int? {
      return self.parseInt(
        from: &index,
        minNumberOfDigits: minNumberOfDigits,
        maxNumberOfDigits: maxNumberOfDigits,
        radix: 10
      )
    }

    guard let hour = __parseDigits() else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: separator) else {
      return nil
    }
    guard let minute = __parseDigits() else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: separator) else {
      return nil
    }
    guard let second = __parseDigits() else {
      return nil
    }

    let result: Output = (hour: hour, minute: minute, second: second)
    return (result, index)
  }
}

// MARK: - Date (RFC 1123 Date / Traditional Cookie Date)

extension _UTF8Parser {
  private func _parseWeekdayCommaSpace(from currentIndex: inout Input.Index) -> Weekday? {
    var index = currentIndex
    guard let weekday = WeekdayParser<Input.SubSequence>.parse(input, from: &index) else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: \._isComma) else {
      return nil
    }
    guard let _ = self.parseHTTPWhitespaces(from: &index) else {
      return nil
    }
    currentIndex = index
    return weekday
  }

  private func _parseSpaceGMT(from currentIndex: inout Input.Index) -> Input.SubSequence? {
    var index = currentIndex
    guard let _ = self.parseHTTPWhitespaces(from: &index) else {
      return nil
    }
    guard let gmt = self.parseASCIICaseInsensitivePrefix("GMT", from: &index) else {
      return nil
    }
    currentIndex = index
    return gmt
  }

  fileprivate func _parseWeekdayDayMonthYearHourMinuteSecondGMT(
    from currentIndex: inout Input.Index,
    dateSeparator: @escaping (Unicode.UTF8.CodeUnit) -> Bool
  ) -> DateComponents? {
    var index = currentIndex

    guard let _ = self._parseWeekdayCommaSpace(from: &index) else {
      return nil
    }

    guard let dmy = DayMonthYearParser<Input>.parse(
      input,
      from: &index,
      separator: dateSeparator
    ) else {
      return nil
    }

    guard let _ = self.parseHTTPWhitespaces(from: &index) else {
      return nil
    }

    guard let hms = HourMinuteSecondParser<Input.SubSequence>.parse(input, from: &index) else {
      return nil
    }

    guard let _ = self._parseSpaceGMT(from: &index) else {
      return nil
    }

    currentIndex = index
    return DateComponents(
      calendar: Calendar(identifier:.gregorian),
      timeZone: TimeZone(secondsFromGMT: 0)!,
      year: dmy.year,
      month: dmy.month.rawValue,
      day: dmy.day,
      hour: hms.hour,
      minute: hms.minute,
      second: hms.second
    )
  }
}

/// A parser to parse a string formatted with the format defined in RFC 1123.
/// e.g.) `Sun, 06 Nov 1994 08:49:37 GMT`
public struct RFC1123DateParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = DateComponents

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public func parse() -> (output: DateComponents, endIndex: Input.Index)? {
    var index = utf8.startIndex
    guard let dateComponents = self._parseWeekdayDayMonthYearHourMinuteSecondGMT(
      from: &index,
      dateSeparator: \._isHTTPWhitespace
    ) else {
      return nil
    }
    return (dateComponents, index)
  }
}

/// A parser to parse a string formatted with the format defined in RFC 1123.
/// e.g.) `Fri, 24-Jan-2003 16:41:00 GMT`
public struct TraditionalHTTPCookieDateParser<Input>: StringParser,
                                                      _UTF8Parser where Input: StringProtocol {
  public typealias Output = DateComponents

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public func parse() -> (output: DateComponents, endIndex: Input.Index)? {
    var index = utf8.startIndex
    guard let dateComponents = self._parseWeekdayDayMonthYearHourMinuteSecondGMT(
      from: &index,
      dateSeparator: \._isHyphen
    ) else {
      return nil
    }
    return (dateComponents, index)
  }
}

// MARK: - cookie-date

private extension Unicode.UTF8.CodeUnit {
  var _isCookieDateDelemiter: Bool {
    return (
      self == 0x09 ||
      (0x20 <= self && self <= 0x2F) ||
      (0x3B <= self && self <= 0x40) ||
      (0x5B <= self && self <= 0x60) ||
      (0x7B <= self && self <= 0x7E)
    )
  }

  var _isCookieDateNonDelimiter: Bool {
    return (
      self <= 0x08 ||
      (0x0A <= self && self <= 0x1F) ||
      self._isDigit ||
      self._isColon ||
      self._isAlphabet ||
      0x7F <= self
    )
  }

  var _isCookieDateNonDigit: Bool {
    return self <= 0x2F || 0x3A <= self
  }
}

/// A parser to parse a date string in the way described in
/// [RFC 6265 §5.1.1](https://datatracker.ietf.org/doc/html/rfc6265#section-5.1.1).
public struct HTTPCookieDateParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = DateComponents

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public func parse() -> (output: DateComponents, endIndex: Input.Index)? {
    var currentIndex = utf8.startIndex

    // Fast-path: RFC 1123 Date or Traditional Cookie Date
    if let dateComponents = self._parseWeekdayDayMonthYearHourMinuteSecondGMT(
      from: &currentIndex,
      dateSeparator: { $0._isHTTPWhitespace || $0._isHyphen }
    ) {
      return (dateComponents, currentIndex)
    }

    func __nextToken() -> Input.SubSequence? {
      _ = self.parseString(from: &currentIndex, while: \._isCookieDateDelemiter)
      return self.parseString(from: &currentIndex, while: \._isCookieDateNonDelimiter)
    }

    var foundTime: (hour: Int, minute: Int, second: Int)? = nil
    var foundDayOfMonth: Int? = nil
    var foundMonth: Month? = nil
    var foundYear: Int? = nil

    while let token = __nextToken() {
      FIND_DATE_ELEMENT: do {
        if foundTime.isNil {
          let timeParser = HourMinuteSecondParser<Input.SubSequence>(
            input: token,
            configuration: .init(
              minNumberOfDigits: 1,
              maxNumberOfDigits: 2,
              separator: \._isColon
            )
          )
          if let (parsedTime, timeEndIndex) = timeParser.parse(),
             timeEndIndex == token.endIndex {
            foundTime = parsedTime
            break FIND_DATE_ELEMENT
          }
        }

        if foundDayOfMonth.isNil {
          var dayParser = DigitParser<Input.SubSequence>(
            input: token,
            minNumberOfDigits: 1,
            maxNumberOfDigits: 2,
            radix: 10
          )
          if let (parsedDay, dayEndIndex) = dayParser.parse() {
            if dayEndIndex == token.endIndex || token.utf8[dayEndIndex]._isCookieDateNonDigit {
              foundDayOfMonth = parsedDay
              break FIND_DATE_ELEMENT
            }
          }
        }

        if foundMonth.isNil {
          if let month = MonthNameParser<Input.SubSequence>.parse(token)?.output {
            foundMonth = month
            break FIND_DATE_ELEMENT
          }
        }

        if foundYear.isNil {
          var yearParser = DigitParser<Input.SubSequence>(
            input: token,
            minNumberOfDigits: 2,
            maxNumberOfDigits: 4,
            radix: 10
          )
          if let (parsedYear, yearEndIndex) = yearParser.parse() {
            if yearEndIndex == token.endIndex || token.utf8[yearEndIndex]._isCookieDateNonDigit {
              foundYear = parsedYear
              break FIND_DATE_ELEMENT
            }
          }
        }
      }

      if !foundTime.isNil && !foundDayOfMonth.isNil && !foundMonth.isNil && !foundYear.isNil {
        break
      }
    }

    guard
      let year = foundYear?._normalizedYear, year > 1600,
      let month = foundMonth,
      let day = foundDayOfMonth, day > 0, day < 32,
      let time = foundTime,
      time.hour >= 0, time.hour <= 24,
      time.minute >= 0, time.minute < 60,
      time.second >= 0, time.second < 60
    else {
      return nil
    }

    let dateComponents = DateComponents(
      calendar: Calendar(identifier: .gregorian),
      timeZone: TimeZone(secondsFromGMT: 0)!,
      year: year,
      month: month.rawValue,
      day: day,
      hour: time.hour,
      minute: time.minute,
      second: time.second,
    )
    return (dateComponents, currentIndex)
  }
}

extension Date {
  /// Initialize with "cookie-date" string.
  /// See [RFC 6265 #5.1.1](https://tools.ietf.org/html/rfc6265#section-5.1.1)
  public init?<S>(cookieDateString string: S) where S: StringProtocol {
    guard let dateComponents = HTTPCookieDateParser<S>.parse(string)?.output,
          let date = dateComponents.date else {
      return nil
    }
    self = date
  }
}


