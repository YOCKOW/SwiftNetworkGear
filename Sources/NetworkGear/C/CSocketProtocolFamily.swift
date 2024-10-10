/***************************************************************************************************
 CSocketProtocolFamily.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CNetworkGear

/// Wrapper for socket protocol.
public struct CSocketProtocolFamily: RawRepresentable, Equatable, Sendable {
  public typealias RawValue = CInt

  public let rawValue: CInt

  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }

  public init(rawValue: Int)  {
    self.rawValue = CInt(rawValue)
  }

  @inlinable
  public init(_ cProtocol: CNWGIPProtocol) {
    self.rawValue = CInt(cProtocol.rawValue)
  }

  public static let unspecified = CSocketProtocolFamily(rawValue:0)
  public static let tcp         = CSocketProtocolFamily(cNWGTransmissionControlProtocol)
  public static let udp         = CSocketProtocolFamily(cNWGUserDatagramProtocol)
}
