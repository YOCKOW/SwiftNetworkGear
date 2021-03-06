/***************************************************************************************************
 CSocketProtocolFamily.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CoreFoundation
import Foundation

/// Wrapper for socket protocol.
public struct CSocketProtocolFamily: RawRepresentable {
  public let rawValue: CInt
  public init(rawValue:CInt) { self.rawValue = rawValue }
  public init(rawValue:Int)  { self.rawValue = CInt(rawValue) } // for Linux
  public static let unspecified = CSocketProtocolFamily(rawValue:0)
  public static let tcp         = CSocketProtocolFamily(rawValue:IPPROTO_TCP)
  public static let udp         = CSocketProtocolFamily(rawValue:IPPROTO_UDP)
}

extension CSocketProtocolFamily: Equatable {}
