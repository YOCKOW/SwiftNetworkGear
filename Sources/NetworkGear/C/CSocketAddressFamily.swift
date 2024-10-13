/***************************************************************************************************
 CAddressFamily.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CNetworkGear

/// Wrapper for `sa_family_t`
public struct CSocketAddressFamily: RawRepresentable, Equatable, Sendable {
  public typealias RawValue = CSocketAddressFamilyValue

  public let rawValue: CSocketAddressFamilyValue
  
  public init(rawValue: CSocketAddressFamilyValue) {
    self.rawValue = rawValue
  }

  public init(rawValue: CInt) {
    self.rawValue = RawValue(rawValue)
  }

  @inlinable
  public init(_ family: CNWGSocketAddressFamily) {
    self.rawValue = RawValue(family.rawValue)
  }

  public static let unspecified = CSocketAddressFamily(cNWGUnspecifiedAddressFamily)
  public static let unix = CSocketAddressFamily(cNWGUNIXAddressFamily)
  public static let ipv4 = CSocketAddressFamily(cNWGIPv4AddressFamily)
  public static let ipv6 = CSocketAddressFamily(cNWGIPv6AddressFamily)
}
