/***************************************************************************************************
 CAddressFamily.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CoreFoundation
import Foundation

/// Wrapper for `sa_family_t`
public struct CSocketAddressFamily: RawRepresentable {
  public let rawValue: sa_family_t
  public init(rawValue:sa_family_t) { self.rawValue = rawValue }
  public init(rawValue:CInt) { self.rawValue = sa_family_t(rawValue) }
  
  public static let unspecified = CSocketAddressFamily(rawValue:AF_UNSPEC)
  public static let unix = CSocketAddressFamily(rawValue:AF_UNIX)
  public static let ipv4 = CSocketAddressFamily(rawValue:AF_INET)
  public static let ipv6 = CSocketAddressFamily(rawValue:AF_INET6)
}

extension CSocketAddressFamily: Equatable {}
