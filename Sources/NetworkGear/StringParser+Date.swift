/* *************************************************************************************************
 StringParser+Date.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

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
    var currentIndex = input.startIndex

    func __parseDayIfPossible()  {
      _ = self.parseASCIICaseInsensitivePrefix("day", from: &currentIndex)
    }

    if let _ = self.parseASCIICaseInsensitivePrefix("sun", from: &currentIndex) {
      __parseDayIfPossible()
      return (.sunday, currentIndex)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("mon", from: &currentIndex) {
      __parseDayIfPossible()
      return (.monday, currentIndex)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("tue", from: &currentIndex) {
      if let _ = self.parseASCIICaseInsensitivePrefix("s", from: &currentIndex) {
        __parseDayIfPossible()
      }
      return (.tuesday, currentIndex)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("wed", from: &currentIndex) {
      if let _ = self.parseASCIICaseInsensitivePrefix("nes", from: &currentIndex) {
        __parseDayIfPossible()
      }
      return (.wednesday, currentIndex)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("thu", from: &currentIndex) {
      // Accept "Thur" too.
      if let _ = self.parseASCIICaseInsensitivePrefix("r", from: &currentIndex),
         let _ = self.parseASCIICaseInsensitivePrefix("s", from: &currentIndex) {
        __parseDayIfPossible()
      }
      return (.thursday, currentIndex)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("fri", from: &currentIndex) {
      __parseDayIfPossible()
      return (.friday, currentIndex)
    } else if let _ = self.parseASCIICaseInsensitivePrefix("sat", from: &currentIndex) {
      _ = self.parseASCIICaseInsensitivePrefix("urday", from: &currentIndex)
      return (.saturday, currentIndex)
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
    var currentIndex = input.startIndex

    func __parse(prefix: String, suffix: String) -> Bool {
      guard let _ = self.parseASCIICaseInsensitivePrefix(prefix, from: &currentIndex) else {
        return false
      }
      _ = self.parseASCIICaseInsensitivePrefix(suffix, from: &currentIndex)
      return true
    }

    if __parse(prefix: "jan", suffix: "uary") {
      return (.january, currentIndex)
    } else if __parse(prefix: "feb", suffix: "ruary") {
      return (.february, currentIndex)
    } else if __parse(prefix: "mar", suffix: "ch") {
      return (.march, currentIndex)
    } else if __parse(prefix: "apr", suffix: "il") {
      return (.april, currentIndex)
    } else if __parse(prefix: "may", suffix: "") {
      return (.may, currentIndex)
    } else if __parse(prefix: "jun", suffix: "e") {
      return (.june, currentIndex)
    } else if __parse(prefix: "jul", suffix: "y") {
      return (.july, currentIndex)
    } else if __parse(prefix: "aug", suffix: "ust") {
      return (.august, currentIndex)
    }  else if __parse(prefix: "sep", suffix: "tember") {
      return (.september, currentIndex)
    } else if __parse(prefix: "oct", suffix: "ober") {
      return (.october, currentIndex)
    } else if __parse(prefix: "nov", suffix: "ember") {
      return (.november, currentIndex)
    } else if __parse(prefix: "dec", suffix: "ember") {
      return (.december, currentIndex)
    }

    return nil
  }
}

extension Month: _InitializableWithParser {
  init?<S>(_ string: S) where S: StringProtocol {
    self.init(string, parser: MonthNameParser<S>.self)
  }
}
