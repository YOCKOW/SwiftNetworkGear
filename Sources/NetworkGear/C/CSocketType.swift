/***************************************************************************************************
 CSocketType.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CNetworkGear

/// Wrapper for `__socket_type`
public struct CSocketType: RawRepresentable, Equatable, Sendable {
  public typealias RawValue = CInt

  public let rawValue: CInt

  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }

  public init(_ cSocketType: CNWGSocketType) {
    self.init(rawValue: CInt(cSocketType.rawValue))
  }

  /// Stream socket
  public static let stream = CSocketType(cNWGStreamSocket)

  /// Datagram socket
  public static let datagram = CSocketType(cNWGDatagramSocket)

  /// Raw protocol socket
  public static let raw = CSocketType(cNWGRawProtocolSocket)

  /// Reliably-delivered message socket
  public static let reliablyDeliveredMessage = CSocketType(cNWGReliablyDeliveredMessageSocket)

  /// Sequenced packet stream socket
  public static let sequencedPacket = CSocketType(cNWGSequencedPacketStreamSocket)
}
