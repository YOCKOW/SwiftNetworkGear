/***************************************************************************************************
 Domain+PublicSuffix.swift
   © 2017-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import PublicSuffix

private extension BidirectionalCollection where Element == Domain.Label {
  /// Returns whether self(not reversed) matches `list` or not.
  /// Punycode encoding must be removed from each label in self.
  func _matches(list: PublicSuffix.Node.Set) -> Bool {
    switch self.count {
    case 0:
      return list.containsTerminationNode()
    case 1:
      if list.containsAnyLabelNode() { return true }
      fallthrough
    default:
      guard case .label(_, next: let nextList) = list.node(of: self.last!._string) else {
        return false
      }
      return self.dropLast()._matches(list: nextList)
    }
  }
  
  var _isPublicSuffix: Bool {
    if self._matches(list: PublicSuffix.positiveList) { return false }
    if self._matches(list: PublicSuffix.negativeList) { return true }
    return false
  }
}

extension Domain {
  /// Check whether the receiver is "public suffix" or not.
  public var isPublicSuffix: Bool {
    return self.removingPunycodeEncoding?._labels._isPublicSuffix ?? false
  }
  
  /// Derive public suffix.
  public var publicSuffix: Domain? {
    guard let labels = self.removingPunycodeEncoding?._labels else { return nil }
    
    for ii in 0..<labels.count {
      let suffix = labels.dropFirst(ii)
      if suffix._isPublicSuffix {
        if ii == 0 {
          return self
        } else {
          return try! Domain(self._labels.dropFirst(ii),
                             terminatedByDot: self.isTerminatedByDot,
                             options: self._options)
        }
      }
    }
    return nil
  }
}
