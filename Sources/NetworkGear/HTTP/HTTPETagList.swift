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
