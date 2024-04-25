/***************************************************************************************************
 CIPv4SocketAddress.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CNetworkGear

/// Extend `CIPv4SocketAddress` (a.k.a. `sockaddr_in`) to make it conform to `CIPSocketAddress`.
extension CIPv4SocketAddress: CIPSocketAddress {
  public typealias ConcreteIPAddress = CIPv4Address
  
  public private(set) var size: CSocketAddressSize {
    get {
      return withUnsafePointer(to: self) { CNWGIPv4SocketAddressSizeOf($0) }
    }
    set {
      #if !os(Linux)
      self.sin_len = newValue
      #endif
    }
  }
  
  public private(set) var family: CSocketAddressFamily {
    get {
      return CSocketAddressFamily(rawValue:self.sin_family) // AF_INET
    }
    set {
      self.sin_family = newValue.rawValue
    }
  }
  
  public var port: CSocketPortNumber {
    get {
      return .init(bigEndian: self.sin_port)
    }
    set {
      self.sin_port = newValue.bigEndian
    }
  }
  
  public private(set) var ipAddress: CIPv4Address {
    get {
      return self.sin_addr
    }
    set {
      self.sin_addr = newValue
    }
  }
  
  public init(ipAddress: CIPv4Address, port: CSocketPortNumber = 80) {
    self.init()
    self.size = CSocketAddressSize(MemoryLayout<CIPv4SocketAddress>.size)
    self.family = .ipv4
    self.port = port
    self.ipAddress = ipAddress
  }
}
