/* *************************************************************************************************
 MIMEDateTimeParser.swift
   © 2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

// Obsoleted things.
extension _UTF8Parser {
  func parseMIMEObsoletedDayOfWeek(from index: inout Self.Input.UTF8View.Index) -> Weekday? {
    var currentIndex = index
    _ = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    guard let weekday = WeekdayParser<Input.SubSequence>.parse(input, from: &currentIndex) else {
      return nil
    }
    _ = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    index = currentIndex
    return weekday
  }

  func parseMIMEObsoletedDay(from index: inout Self.Input.UTF8View.Index) -> Int? {
    var currentIndex = index
    _ = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    guard let day = self.parseInt(from: &currentIndex, maxNumberOfDigits: 2) else {
      return nil
    }
    _ = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    index = currentIndex
    return day
  }

  func parseMIMEObsoletedYear(from index: inout Self.Input.UTF8View.Index) -> Int? {
    var currentIndex = index
    _ = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    guard var year = self.parseInt(from: &currentIndex, minNumberOfDigits: 2) else {
      return nil
    }
    _ = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    index = currentIndex

    switch year {
    case 0...49: year += 2000
    case 50...99: year += 1900
    default: break
    }
    return year
  }

  private func _parseObsoletedTwoDigits(from index: inout Self.Input.UTF8View.Index) -> Int? {
    var currentIndex = index
    _ = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    guard let int = self.parseInt(from: &currentIndex, minNumberOfDigits: 2, maxNumberOfDigits: 2) else {
      return nil
    }
    _ = MIMECommentCoexistableFoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    index = currentIndex
    return int
  }

  func parseMIMEObsoletedHour(from index: inout Self.Input.UTF8View.Index) -> Int? {
    return _parseObsoletedTwoDigits(from: &index)
  }

  func parseMIMEObsoletedMinute(from index: inout Self.Input.UTF8View.Index) -> Int? {
    return _parseObsoletedTwoDigits(from: &index)
  }

  func parseMIMEObsoletedSecond(from index: inout Self.Input.UTF8View.Index) -> Int? {
    return _parseObsoletedTwoDigits(from: &index)
  }

  func parseMIMEObsoletedTimeZone(from index: inout Self.Input.UTF8View.Index) -> (hour: Int, minute: Int)? {
    var currentIndex = index

    func __parse() -> (hour: Int, minute: Int)? {
      func __zone(_ prefix: String) -> Bool {
        return !self.parseASCIICaseInsensitivePrefix(prefix, from: &currentIndex).isNil
      }

      if __zone("UT") || __zone("GMT") {
        return (0, 0)
      }
      if __zone("EST") {
        return (-5, 0)
      }
      if __zone("EDT") {
        return (-4, 0)
      }
      if __zone("CST") {
        return (-6, 0)
      }
      if __zone("CDT") {
        return (-5, 0)
      }
      if __zone("MST") {
        return (-7, 0)
      }
      if __zone("MDT") {
        return (-6, 0)
      }
      if __zone("PST") {
        return (-8, 0)
      }
      if __zone("PDT") {
        return (-7, 0)
      }

      // The 1 character military time zone
      guard let byte = self.readCurrentCodeUnit(at: &currentIndex) else {
        return nil
      }
      switch byte {
      case 0x41...0x49: // A...I
        return (Int(byte - 0x40), 0)
      case 0x61...0x69: // a...i
        return (Int(byte - 0x60), 0)
      case 0x4B...0x4D: // K, L, M
        return (Int(byte - 0x4B + 10), 0)
      case 0x6B...0x6D: // k, l, m
        return (Int(byte - 0x6B + 10), 0)
      case 0x4E...0x59: // N...Y
        return (-Int(byte - 0x4D), 0)
      case 0x6E...0x79: // n...y
        return (-Int(byte - 0x6D), 0)
      case 0x5A, 0x7A: // Z, z
        return (0, 0)
      default:
        break
      }

      return nil
    }

    guard let offset = __parse() else {
      return nil
    }
    index = currentIndex
    return offset
  }
}


extension _UTF8Parser {
  func parseMIMEDayOfWeek(from index: inout Self.Input.UTF8View.Index) -> Weekday? {
    var currentIndex = index
    _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    guard let weekday = WeekdayParser<Input.SubSequence>.parse(input, from: &currentIndex) else {
      return nil
    }
    index = currentIndex
    return weekday
  }

  func parseMIMEDay(from index: inout Self.Input.UTF8View.Index) -> Int? {
    var currentIndex = index
    _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    guard let int = self.parseInt(from: &currentIndex, maxNumberOfDigits: 2) else {
      return nil
    }
    _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)
    index = currentIndex
    return int
  }

  func parseMIMEYear(from index: inout Self.Input.UTF8View.Index) -> Int? {
    var currentIndex = index
    guard let _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex) else {
      return nil
    }
    guard let int = self.parseInt(from: &currentIndex, minNumberOfDigits: 4) else {
      return nil
    }
    guard let _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex) else {
      return nil
    }
    index = currentIndex
    return int
  }

  func parseMIMEHour(from index: inout Self.Input.UTF8View.Index) -> Int? {
    return self.parseInt(from: &index, minNumberOfDigits: 2, maxNumberOfDigits: 2)
  }

  func parseMIMEMinute(from index: inout Self.Input.UTF8View.Index) -> Int? {
    return self.parseInt(from: &index, minNumberOfDigits: 2, maxNumberOfDigits: 2)
  }

  func parseMIMESecond(from index: inout Self.Input.UTF8View.Index) -> Int? {
    return self.parseInt(from: &index, minNumberOfDigits: 2, maxNumberOfDigits: 2)
  }

  func parseMIMETimeZone(from index: inout Self.Input.UTF8View.Index) -> (hour: Int, minute: Int)? {
    var currentIndex = index

    // Make `FWS` optional because of compatibility for "obsoleted" parsing.
    _ = FoldingWhitespaceParser<Input.SubSequence>.parse(input, from: &currentIndex)

    guard
      let plusOrMinus = self.readCurrentCodeUnit(
        at: &currentIndex,
        ifAllowedCodeUnit: { $0 == ._plusSign || $0 == ._hyphen }
      ),
      let hour = self.parseInt(from: &currentIndex, minNumberOfDigits: 2, maxNumberOfDigits: 2),
      let minute = self.parseInt(from: &currentIndex, minNumberOfDigits: 2, maxNumberOfDigits: 2)
    else {
      return nil
    }
    if plusOrMinus == ._hyphen {
      return (-hour, -minute)
    } else {
      return (hour, minute)
    }
  }
}

public struct MIMEDateTimeParserConfiguration: Sendable {
  public var allowObsoletedForms: Bool

  @inlinable
  public init(allowObsoletedForms: Bool = false) {
    self.allowObsoletedForms = allowObsoletedForms
  }

  public static let `default`: MIMEDateTimeParserConfiguration = .init()
}

/// A parser to parse `date-time` defined in [RFC 5322 §3.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.3).
public struct MIMEDateTimeParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = DateComponents

  public typealias Configuration = MIMEDateTimeParserConfiguration

  @usableFromInline let input: Input
  @usableFromInline let utf8: Input.UTF8View

  public var configuration: Configuration

  @inlinable
  public var allowObsoletedForms: Bool {
    get { configuration.allowObsoletedForms }
    set { configuration.allowObsoletedForms = newValue }
  }

  @inlinable
  public init(input: Input, configuration: Configuration? = nil) {
    self.input = input
    self.utf8 = input.utf8
    self.configuration = configuration ?? .default
  }

  @inlinable
  public init(input: Input, allowObsoletedForms: Bool) {
    self.init(input: input, configuration: .init(allowObsoletedForms: allowObsoletedForms))
  }

  public mutating func parse() -> (output: DateComponents, endIndex: Input.Index)? {
    var currentIndex = self.utf8.startIndex

    let (
      dayOfWeekParser,
      dayParser,
      monthParser,
      yearParser,
      hourParser,
      minuteParser,
      secondParser,
    ): (
      (Self) -> Weekday?,
      (Self) -> Int?,
      (Self) -> Month?,
      (Self) -> Int?,
      (Self) -> Int?,
      (Self) -> Int?,
      (Self) -> Int?,
    ) = (
      self.configuration.allowObsoletedForms ? (
        { $0.parseMIMEObsoletedDayOfWeek(from: &currentIndex) },
        { $0.parseMIMEObsoletedDay(from: &currentIndex) },
        { MonthNameParser<Input.SubSequence>.parse($0.input, from: &currentIndex) },
        { $0.parseMIMEObsoletedYear(from: &currentIndex) },
        { $0.parseMIMEObsoletedHour(from: &currentIndex) },
        { $0.parseMIMEObsoletedMinute(from: &currentIndex) },
        { $0.parseMIMEObsoletedSecond(from: &currentIndex) },
      ) : (
        { $0.parseMIMEDayOfWeek(from: &currentIndex) },
        { $0.parseMIMEDay(from: &currentIndex) },
        { MonthNameParser<Input.SubSequence>.parse($0.input, from: &currentIndex) },
        { $0.parseMIMEYear(from: &currentIndex) },
        { $0.parseMIMEHour(from: &currentIndex) },
        { $0.parseMIMEMinute(from: &currentIndex) },
        { $0.parseMIMESecond(from: &currentIndex) },
      )
    )

    let zoneParser: (Self) -> (hour: Int, minute: Int)? = {
      return (
        $0.parseMIMETimeZone(from: &currentIndex) ??
        $0.parseMIMEObsoletedTimeZone(from: &currentIndex)
      )
    }

    func __readColon() -> Bool {
      return !self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isColon).isNil
    }

    if let _ = dayOfWeekParser(self) {
      guard let _ = self.readCurrentCodeUnit(at: &currentIndex, ifAllowedCodeUnit: \._isComma) else {
        return nil
      }
    }

    guard let day = dayParser(self),
          let month = monthParser(self),
          let year = yearParser(self),
          let hour = hourParser(self),
          __readColon(),
          let minute = minuteParser(self) else {
      return nil
    }

    var second: Int? = nil
    if __readColon() {
      guard let parsedSecond = secondParser(self) else {
        return nil
      }
      second = parsedSecond
    }

    guard let offset = zoneParser(self) else {
      return nil
    }

    let dateComponents = DateComponents(
      calendar: Calendar(identifier: .gregorian),
      timeZone: TimeZone(secondsFromGMT: offset.hour * 60 * 60 + offset.minute * 60),
      year: year,
      month: month.rawValue,
      day: day,
      hour: hour,
      minute: minute,
      second: second
    )

    return (dateComponents, currentIndex)
  }
}
