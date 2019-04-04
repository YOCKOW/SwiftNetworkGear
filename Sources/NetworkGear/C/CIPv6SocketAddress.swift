/***************************************************************************************************
 CIPv6SocketAddress.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CoreFoundation

extension CIPv6SocketAddress: CIPSocketAddress {
  public private(set) var size: CSocketAddressSize {
    get {
      #if !os(Linux)
      return self.sin6_len
      #else
      return CSocketAddressSize(MemoryLayout<CIPv6SocketAddress>.size)
      #endif
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
      return CFSwapInt16BigToHost(self.sin6_port)
    }
    set {
      self.sin6_port = CFSwapInt16HostToBig(newValue)
    }
  }
  
  public private(set) var ipAddress: CIPAddress {
    get {
      return self.sin6_addr
    }
    set {
      guard newValue is CIPv6Address else { fatalError("Requires CIPv6Address") }
      self.sin6_addr = newValue as! CIPv6Address
    }
  }
  
  public init?(ipAddress:CIPAddress, port:CSocketPortNumber = 80) {
    guard ipAddress is CIPv6Address else { return nil }
    self.init(ipv6Address:ipAddress as! CIPv6Address, port:port)
  }
}


extension CIPv6SocketAddress {
  /// Returns flow identifier of IPv6
  public var flowIdentifier: CIPv6FlowIdentifier {
    get {
      return CFSwapInt32BigToHost(self.sin6_flowinfo)
    }
    set {
      self.sin6_flowinfo = CFSwapInt32HostToBig(newValue)
    }
  }
  
  /// Returns Scope ID of IPv6
  public var scopeIdentifier: CIPv6ScopeIdentifier {
    get {
      return CFSwapInt32BigToHost(self.sin6_scope_id)
    }
    set {
      self.sin6_scope_id = CFSwapInt32HostToBig(newValue)
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
