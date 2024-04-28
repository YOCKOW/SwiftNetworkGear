/***************************************************************************************************
 CSocketAddress.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CNetworkGear

extension UnsafePointer where Pointee == CSocketAddress {
  public var family: CSocketAddressFamily {
    return CSocketAddressFamily(rawValue: pointee.sa_family)
  }

  internal var actualSocketAddress: any CSocketAddressStructure {
    switch family {
    case .unix:
      return withMemoryRebound(to: CUNIXSocketAddress.self, capacity: 1) {
        return $0.pointee
      }
    case .ipv4:
      return withMemoryRebound(to: CIPv4SocketAddress.self, capacity: 1) {
        return $0.pointee
      }
    case .ipv6:
      return withMemoryRebound(to: CIPv6SocketAddress.self, capacity: 1) {
        return $0.pointee
      }
    default:
      fatalError("Unimplemented family: \(family)")
    }
  }

  public var size: CSocketAddressSize {
    #if !os(Linux)
    return pointee.sa_len
    #else
    return actualSocketAddress.size
    #endif
  }
}

/// Extend `CSocketAddress` (a.k.a. `sockaddr`)
@available(*, deprecated, message: "Use `UnsafePointer<CSocketAddress>` extension instead.")
extension CSocketAddress {
  internal static func actualSocketAddress(`for` pointer: UnsafePointer<CSocketAddress>) -> any CSocketAddressStructure {
    return pointer.actualSocketAddress
  }
  
  public var family: CSocketAddressFamily {
    get {
      return CSocketAddressFamily(rawValue:self.sa_family)
    }
  }
  
  public var size: CSocketAddressSize {
    mutating get {
      #if !os(Linux)
      return self.sa_len
      #else
      return withUnsafePointer(to:&self) {
        return CSocketAddress.actualSocketAddress(for:$0).size
      }
      #endif
    }
  }
}
