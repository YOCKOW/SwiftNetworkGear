/* *************************************************************************************************
 ETagList.swift
   © 2018-2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Represents the list of `ETag`s
public enum HTTPETagList: Sendable {
  case any
  case list(Array<HTTPETag>)
}

extension HTTPETagList {
  /// Appends a new ETag.
  public mutating func append(_ newETag:HTTPETag) {
    switch self {
    case .any: break
    case .list(var array):
      if array.contains(newETag) { break }
      array.append(newETag)
      self = .list(array)
    }
  }
}

infix operator =~: ComparisonPrecedence
extension HTTPETagList {
  public func contains(_ tag:HTTPETag, weakComparison:Bool = false) -> Bool {
    switch self {
    case .any:
      return true
    case .list(let array):
      let predicate:(HTTPETag) -> Bool = weakComparison ? { $0 =~ tag } : { $0 == tag }
      return array.contains(where:predicate)
    }
  }
}

extension HTTPETagList: Hashable {
  public static func ==(lhs:HTTPETagList, rhs:HTTPETagList) -> Bool {
    switch (lhs, rhs) {
    case (.any, .any): return true
    case (.list(let larray), .list(let rarray)): return larray == rarray
    default: return false
    }
  }
  
  public func hash(into hasher:inout Hasher) {
    switch self {
    case .any: hasher.combine(Int.max)
    case .list(let array): hasher.combine(array)
    }
  }
}

extension HTTPETagList: CustomStringConvertible {
  public var description: String {
    switch self {
    case .any: return "*"
    case .list(let array): return array.map{ $0.description }.joined(separator:", ")
    }
  }
}


/// A parser to parse a list of `HTTPETag`s.
public struct HTTPETagListParser<Input>: StringParser, _UTF8Parser where Input: StringProtocol {
  public typealias Output = HTTPETagList

  let input: Input
  let utf8: Input.UTF8View

  public init(input: Input) {
    self.input = input
    self.utf8 = input.utf8
  }

  public mutating func parse() -> (output: HTTPETagList, endIndex: Input.Index)? {
    guard let firstByte = utf8.first else {
      return nil
    }

    if firstByte._isAsterisk {
      return (.any, self.utf8.index(after: self.utf8.startIndex))
    }

    var currentIndex = self.utf8.startIndex
    var tagSet: Set<HTTPETag> = []
    var tagList: Array<HTTPETag> = []

    func __consumeSeparator() -> Bool {
      !self.parseString(from: &currentIndex, while: { $0._isHTTPWhitespace || $0._isComma }).isNil
    }

    while currentIndex < self.utf8.endIndex {
      guard let (tag, endIndex) = HTTPETagParser<Input.SubSequence>.parse(input[currentIndex...]) else {
        break
      }

      APPEND: do {
        if case .any = tag {
          return nil
        }
        if tagSet.contains(tag) {
          break APPEND
        }
        tagSet.insert(tag)
        tagList.append(tag)
      }
      currentIndex = endIndex

      guard __consumeSeparator() else {
        break
      }
    }

    return (.list(tagList), currentIndex)
  }
}

extension HTTPETagList: _InitializableWithParser {
  /// Initialize from `string`.
  /// - parameter string: such as ` "A", "B", W/"C" `
  public init?<S>(string: S) where S: StringProtocol {
    self.init(string, parser: HTTPETagListParser<S>.self)
  }
}
