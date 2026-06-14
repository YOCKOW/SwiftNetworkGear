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
    let separator: (Unicode.UTF8.CodeUnit) -> Bool
    
    init(separator: @escaping (Unicode.UTF8.CodeUnit) -> Bool) {
      self.separator = separator
    }
  }

  let input: Input
  let utf8: Input.UTF8View
  let configuration: Configuration?
  var separator: (Unicode.UTF8.CodeUnit) -> Bool { configuration?.separator ?? \._isColon }

  init(input: Input, configuration: Configuration?) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration
  }

  func parse() -> (output: Output, endIndex: Input.Index)? {
    var index = utf8.startIndex

    func __parse2Digits() -> Int? {
      return self.parseInt(from: &index, minNumberOfDigits: 2, maxNumberOfDigits: 2, radix: 10)
    }

    guard let hour = __parse2Digits() else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: separator) else {
      return nil
    }
    guard let minute = __parse2Digits() else {
      return nil
    }
    guard let _ = self.readCurrentCodeUnit(at: &index, ifAllowedCodeUnit: separator) else {
      return nil
    }
    guard let second = __parse2Digits() else {
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
    guard let _ = self.parseSpaces(from: &index) else {
      return nil
    }
    currentIndex = index
    return weekday
  }

  private func _parseSpaceGMT(from currentIndex: inout Input.Index) -> Input.SubSequence? {
    var index = currentIndex
    guard let _ = self.parseSpaces(from: &index) else {
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

    guard let _ = self.parseSpaces(from: &index) else {
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


private extension Unicode.Scalar {
  var _isCookieDateSeparator: Bool {
    switch value {
    case 0x09, 0x20...0x2F, 0x3B...0x40, 0x5B...0x60, 0x7B...0x7E:
      return true
    default:
      return false
    }
  }

  var _isNumber: Bool { 0x30 <= value && value <= 0x39 }
}

private func _convert_year<C>(_ scalars: C) -> Int? where C: Collection, C.Element == Unicode.Scalar {
  var output = String.UnicodeScalarView()
  for scalar in scalars {
    guard scalar._isNumber else { break }
    output.append(scalar)
  }
  guard output.count >= 2 else { return nil }
  guard let result = Int(String(String.UnicodeScalarView(output))) else { return nil }
  switch result {
  case 0...69: return result + 2000
  case 70...99: return result + 1900
  default: break
  }
  guard result > 1600 else { return nil }
  return result
}

private func _convert_month<C>(_ scalars: C) -> Int8? where C: Collection, C.Element == Unicode.Scalar {
  guard scalars.count >= 3 else { return nil }
  let prefix = String(String.UnicodeScalarView(scalars.prefix(3)))
  switch prefix.lowercased() {
  case "jan": return 1
  case "feb": return 2
  case "mar": return 3
  case "apr": return 4
  case "may": return 5
  case "jun": return 6
  case "jul": return 7
  case "aug": return 8
  case "sep": return 9
  case "oct": return 10
  case "nov": return 11
  case "dec": return 12
  default: return nil
  }
}

private func _convert_day<C>(_ scalars: C) -> Int8? where C: Collection, C.Element == Unicode.Scalar {
  var output = String.UnicodeScalarView()
  for scalar in scalars {
    guard scalar._isNumber else { break }
    output.append(scalar)
  }
  guard output.count >= 2 else { return nil }
  guard let result = Int8(String(String.UnicodeScalarView(output))), result > 0, result < 32 else { return nil }
  return result
}

private func _convert_time<C>(_ scalars: C) -> (hour:Int8, minute:Int8, second:Int8)? where C: Collection, C.Element == Unicode.Scalar {
  let components = scalars.split(separator: ":")
  guard components.count >= 3 else { return nil }

  func __int8<S>(from scalars: S) -> Int8? where S: Sequence, S.Element == Unicode.Scalar {
    Int8(String(String.UnicodeScalarView(scalars)))
  }

  guard let hour = __int8(from: components[0]), hour >= 0, hour < 24 else { return nil }
  guard let min = __int8(from: components[1]), min >= 0, min < 60 else { return nil }
  var secScalars = String.UnicodeScalarView()
  for scalar in components[2] {
    guard scalar._isNumber else { break }
    secScalars.append(scalar)
  }
  guard secScalars.count >= 1 else { return nil }
  guard let sec = __int8(from: secScalars), sec >= 0, sec <= 60 else { return nil }
  return (hour:hour, minute:min, second:sec)
}

extension Date {
  /// Initialize with "cookie-date" string.
  /// See [RFC 6265 #5.1.1](https://tools.ietf.org/html/rfc6265#section-5.1.1)
  public init?(cookieDateString string:String) {
    if let date = DateFormatter.rfc1123.date(from:string) {
      self.init(timeInterval:0, since:date)
    } else if let date = DateFormatter.traditionalHTTPCookie.date(from:string) {
      self.init(timeInterval:0, since:date)
    } else {
      let components = string.unicodeScalars.split(whereSeparator: \._isCookieDateSeparator).filter({ !$0.isEmpty })

      var year: Int = 0
      var month: Int8 = 0
      var day: Int8 = 0
      var time: (hour:Int8, minute:Int8, second:Int8) = (hour:-1, minute:-1, second:-1)
      
      // parse
      for component in components {
        if time.hour < 0, let tt = _convert_time(component) {
          time = tt
        } else if day < 1, let dd = _convert_day(component) {
          day = dd
        } else if month < 1, let mm = _convert_month(component) {
          month = mm
        } else if year < 1, let yy = _convert_year(component) {
          year = yy
        }
      }
      
      guard year > 1600 && day >= 1 && day <= 31 && time.hour >= 0 && time.hour < 24 &&
        time.minute >= 0 && time.minute <= 59 && time.second >= 0 && time.second <= 60 else {
          return nil
      }
      
      let dateComponents = DateComponents(
        calendar:Calendar(identifier:.gregorian),
        timeZone:TimeZone(secondsFromGMT:0)!,
        year:year,
        month:Int(month),
        day:Int(day),
        hour:Int(time.hour),
        minute:Int(time.minute),
        second:Int(time.second)
      )
      
      guard let date = dateComponents.date else { return nil }
      self.init(timeInterval:0, since:date)
    }
  }
}


