/***************************************************************************************************
 CAddressFamily.swift
   © 2017-2018, 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import _NGCExtensionsSupport

/// Wrapper for `sa_family_t`
public struct CSocketAddressFamily: RawRepresentable {
  public let rawValue: sa_family_t
  public init(rawValue: sa_family_t) { self.rawValue = rawValue }
  public init(rawValue: CInt) { self.rawValue = _NGCESocketAddressFamily(rawValue) }
  
  public static let unspecified = CSocketAddressFamily(rawValue: _kNGCESocketAddressFamilyUnspecified)
  public static let unix = CSocketAddressFamily(rawValue: _kNGCESocketAddressFamilyUNIX)
  public static let ipv4 = CSocketAddressFamily(rawValue: _kNGCESocketAddressFamilyIPv4)
  public static let ipv6 = CSocketAddressFamily(rawValue: _kNGCESocketAddressFamilyIPv6)
}

extension CSocketAddressFamily: Equatable {}
