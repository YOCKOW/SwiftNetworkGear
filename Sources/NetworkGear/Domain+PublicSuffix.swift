/***************************************************************************************************
 Domain+PublicSuffix.swift
   © 2017-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import PublicSuffix

extension Domain {
  /// Returns whether the receiver matches `list` or not.
  /// `list` represents the tree of `PublicSuffix`
  private func _matches(list: PublicSuffix.Node.Set) -> Bool {
    guard let labels = self.removingPunycodeEncoding?._labels else { return false }
    let nn = labels.count
    var listNow: PublicSuffix.Node.Set = list
    for ii in (0..<nn).reversed() {
      if ii == 0 && listNow.containsAnyLabelNode() { return true }
      
      let label_string = labels[ii].description
      guard let node = listNow.node(of: label_string) else { return false }
      
      switch (ii, node) {
      case (0, .label(_, next: let list)):
        return list.containsTerminationNode()
      case (_, .label(_, next: let list)):
        // continue
        listNow = list
      default:
        return false
      }
    }
    return false
  }
  
  /// Check whether the receiver is "public suffix" or not.
  public var isPublicSuffix: Bool {
    get {
      if self._matches(list: PublicSuffix.positiveList) { return false }
      if self._matches(list: PublicSuffix.negativeList) { return true }
      return false
    }
  }
  
  /// Extract public suffix.
  public var publicSuffix: Domain? {
    if self.isPublicSuffix { return self }
    
    let labels = self._labels
    let nn = labels.count
    for ii in 1..<nn {
      let domain_string = labels[ii..<nn].map{ $0.description }.joined(separator:".")
      guard let domain = Domain(domain_string, options:self._options) else { return nil }
      if domain.isPublicSuffix { return domain }
    }
    return nil
  }
}
