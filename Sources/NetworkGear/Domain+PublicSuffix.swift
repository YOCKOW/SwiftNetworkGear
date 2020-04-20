/***************************************************************************************************
 Domain+PublicSuffix.swift
   © 2017-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import PublicSuffix

extension Domain {
  /// Returns whether self(not reversed) matches `list` or not.
  /// Punycode encoding must be removed from each label in self.
  private func _matches(list: PublicSuffix.Node.Set) -> Bool {
    switch (self.count, list.node(of: self.last!._string)) {
    case (1, .label(_, next: let nextList)):
      return nextList.containsTerminationNode()
    case (1, _):
      return list.containsAnyLabelNode()
    case (_, .label(_, next: let nextList)):
      return self.dropLast()._matches(list: nextList)
    default:
      return false
    }
  }
  
  /// Returns whether self is "PublicSuffix" or not.
  /// Punycode encoding must be removed from each label in self.
  private var _isPublicSuffix: Bool {
    if self._matches(list: PublicSuffix.positiveList) { return false }
    if self._matches(list: PublicSuffix.negativeList) { return true }
    return false
  }
  
  /// Check whether the receiver is "public suffix" or not.
  public var isPublicSuffix: Bool {
    return self.removingPunycodeEncoding?._isPublicSuffix ?? false
  }
  
  /// Derive public suffix.
  public var publicSuffix: Domain? {
    guard let domain = self.removingPunycodeEncoding else { return nil }
    
    for ii in 0..<domain.count {
      let suffix = domain.dropFirst(ii)
      if suffix._isPublicSuffix {
        if ii == 0 {
          return self
        } else {
          return suffix
        }
      }
    }
    return nil
  }
  
  /// Returns domain removing PublicSuffix, or `nil` when `self` itself is PublicSuffix.
  public func dropPublicSuffix() -> Domain? {
    guard let publicSuffix = self.publicSuffix else { return self }
    let droppingCount = publicSuffix.count
    if droppingCount == self.count {
      return nil
    } else {
      return self.dropLast(droppingCount)
    }
  }
}
