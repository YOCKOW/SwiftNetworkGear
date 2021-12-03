/***************************************************************************************************
 CSocketType.swift
   © 2017-2018, 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import _NGCExtensionsSupport

/// Wrapper for `__socket_type`
public struct CSocketType: RawRepresentable {
  public let rawValue: CSocketTypeValue
  public init(rawValue: CSocketTypeValue) { self.rawValue = rawValue }
  #if os(Linux)
  public init(rawValue: __socket_type) { self.rawValue = CSocketTypeValue(rawValue.rawValue) }
  #endif
  
  public static let stream = CSocketType(rawValue: _kNGCESocketTypeStream)
  public static let datagram = CSocketType(rawValue: _kNGCESocketTypeDatagram)
  public static let raw = CSocketType(rawValue: _kNGCESocketTypeRaw)
  public static let reliablyDeliveredMessage = CSocketType(rawValue: _kNGCESocketTypeReliablyDeliveredMessage)
  public static let sequencedPacket = CSocketType(rawValue: _kNGCESOcketTypeSequencedPacket)
}

extension CSocketType: Equatable {}
