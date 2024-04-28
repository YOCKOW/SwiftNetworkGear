/***************************************************************************************************
 CIPv6SocketAddress.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CNetworkGear

extension CIPv6SocketAddress: CIPSocketAddress {
  public typealias ConcreteIPAddress = CIPv6Address
  
  public private(set) var size: CSocketAddressSize {
    get {
      return withUnsafePointer(to: self) { CNWGIPv6SocketAddressSizeOf($0) }
    }
    set {
      #if !os(Linux)
      self.sin6_len = newValue
      #endif
    }
  }
  
  public private(set) var family: CSocketAddressFamily {
    get {
      return CSocketAddressFamily(rawValue:self.sin6_family) // AF_INET6
    }
    set {
      self.sin6_family = newValue.rawValue
    }
  }
  
  public var port: CSocketPortNumber {
    get {
      return .init(bigEndian: self.sin6_port)
    }
    set {
      self.sin6_port = newValue.bigEndian
    }
  }
  
  public private(set) var ipAddress: CIPv6Address {
    get {
      return self.sin6_addr
    }
    set {
      self.sin6_addr = newValue
    }
  }
  
  public init(ipAddress: CIPv6Address, port: CSocketPortNumber = 80) {
    self.init(ipv6Address: ipAddress, port: port)
  }
}


extension CIPv6SocketAddress {
  /// Returns flow identifier of IPv6
  public var flowIdentifier: CIPv6FlowIdentifier {
    get {
      return .init(bigEndian: self.sin6_flowinfo)
    }
    set {
      self.sin6_flowinfo = newValue.bigEndian
    }
  }
  
  /// Returns Scope ID of IPv6
  public var scopeIdentifier: CIPv6ScopeIdentifier {
    get {
      return .init(bigEndian: self.sin6_scope_id)
    }
    set {
      self.sin6_scope_id = newValue.bigEndian
    }
  }
  
  public init(ipv6Address:CIPv6Address, port:CSocketPortNumber = 80,
              flowIdentifier:CIPv6FlowIdentifier = 0, scopeIdentifier:CIPv6ScopeIdentifier = 0) {
    self.init()
    self.size = CSocketAddressSize(MemoryLayout<CIPv6SocketAddress>.size)
    self.family = .ipv6
    self.port = port
    self.flowIdentifier = flowIdentifier
    self.ipAddress = ipv6Address
    self.scopeIdentifier = scopeIdentifier
  }
}
