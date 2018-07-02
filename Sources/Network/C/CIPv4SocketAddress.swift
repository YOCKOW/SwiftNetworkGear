/***************************************************************************************************
 CIPv4SocketAddress.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CoreFoundation

/// Extend `CIPv4SocketAddress` (a.k.a. `sockaddr_in`) to make it conform to `CIPSocketAddress`.
extension CIPv4SocketAddress: CIPSocketAddress {
  public private(set) var size: CSocketAddressSize {
    get {
      #if !os(Linux)
      return self.sin_len
      #else
      return CSocketAddressSize(MemoryLayout<CIPv4SocketAddress>.size)
      #endif
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
      return CFSwapInt16BigToHost(self.sin_port)
    }
    set {
      self.sin_port = CFSwapInt16HostToBig(newValue)
    }
  }
  
  public private(set) var ipAddress: CIPAddress {
    get {
      return self.sin_addr
    }
    set {
      guard newValue is CIPv4Address else { fatalError("Requires CIPv4Address") }
      self.sin_addr = newValue as! CIPv4Address
    }
  }
  
  public init?(ipAddress:CIPAddress, port:CSocketPortNumber = 80) {
    guard ipAddress is CIPv4Address else { return nil }
    self.init()
    self.size = CSocketAddressSize(MemoryLayout<CIPv4SocketAddress>.size)
    self.family = .ipv4
    self.port = port
    self.ipAddress = ipAddress
  }
}
