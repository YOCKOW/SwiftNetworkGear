/***************************************************************************************************
 CSocketProtocolFamily.swift
   © 2017-2018, 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import _NGCExtensionsSupport

/// Wrapper for socket protocol.
public struct CSocketProtocolFamily: RawRepresentable {
  public let rawValue: CSocketProtocolFamilyValue
  public init(rawValue: CSocketProtocolFamilyValue) { self.rawValue = rawValue }
  public init(rawValue: Int)  { self.rawValue = CSocketProtocolFamilyValue(rawValue) } // for Linux
  public static let unspecified = CSocketProtocolFamily(rawValue:0)
  public static let tcp         = CSocketProtocolFamily(rawValue: _kNGCESocketProtocolFamilyTCP)
  public static let udp         = CSocketProtocolFamily(rawValue: _kNGCESocketProtocolFamilyUDP)
}

extension CSocketProtocolFamily: Equatable {}
