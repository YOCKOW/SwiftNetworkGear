/***************************************************************************************************
 IPAddress.swift
   © 2017-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import Foundation

/**
 
 # IPAddress
 Represents IP Address.
 
 */
public enum IPAddress {
  case v4(UInt8, UInt8, UInt8, UInt8)
  case v6(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
          UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}

extension IPAddress {
  /// Initialize with the array of `UInt8`.
  /// - parameter bytes: the array of `UInt8` representing IP Address.
  /// - returns: `.v4` address if the length of bytes is equal to 4,
  ///            `.v6` address if the length of bytes is equal to 6,
  ///            `nil` if otherwise.
  public init?(bytes:[UInt8]) {
    if bytes.count == 4 {
      self = .v4(bytes[0], bytes[1], bytes[2], bytes[3])
    } else if bytes.count == 16 {
      self = .v6(bytes[0], bytes[1], bytes[2], bytes[3],
                 bytes[4], bytes[5], bytes[6], bytes[7],
                 bytes[8], bytes[9], bytes[10], bytes[11],
                 bytes[12], bytes[13], bytes[14], bytes[15])
    } else {
      return nil
    }
  }
  
  /// Initialize with the string.
  /// - parameter string: the string representing IP Address.
  /// - returns: `.v4` address if the string is valid for IPv4,
  ///            `.v6` address if the string is valid for IPv6,
  ///            `nil` if otherwise.
  public init?(string:String) {
    if let bytes = ({ (string:String) -> [UInt8]? in
      if let ipv4 = CIPv4Address(string:string) { return ipv4.bytes }
      if let ipv6 = CIPv6Address(string:string) { return ipv6.bytes }
      return nil
    })(string) {
      self.init(bytes:bytes)
    } else {
      return nil
    }
  }
}

private extension IPAddress {
  func _withUnsafeBufferPointer<Result>(_ body: (UnsafeBufferPointer<UInt8>) throws -> Result) rethrows -> Result {
    let capacity: Int
    switch self {
    case .v4: capacity = 4
    case .v6: capacity = 16
    }
    let pointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: capacity)
    defer { pointer.deallocate() }
    
    switch self {
    case .v4(let b0, let b1, let b2, let b3):
      pointer[0] = b0
      pointer[1] = b1
      pointer[2] = b2
      pointer[3] = b3
    case .v6(let b0, let b1, let  b2, let  b3, let  b4, let  b5, let  b6, let  b7,
             let b8, let b9, let b10, let b11, let b12, let b13, let b14, let b15):
      pointer[0] = b0
      pointer[1] = b1
      pointer[2] = b2
      pointer[3] = b3
      pointer[4] = b4
      pointer[5] = b5
      pointer[6] = b6
      pointer[7] = b7
      pointer[8] = b8
      pointer[9] = b9
      pointer[10] = b10
      pointer[11] = b11
      pointer[12] = b12
      pointer[13] = b13
      pointer[14] = b14
      pointer[15] = b15
    }
    
    return try body(.init(pointer))
  }
}

/// Handles IPv4-Mapped Address
extension IPAddress {
  /// Check whether the instance is IPv4-mapped or not. Returns `false` if the instance is `.v4`.
  public var isIPv4Mapped: Bool {
    guard case .v6 = self else { return false }
    return _withUnsafeBufferPointer {
      for ii in 0...9 {
        guard $0[ii] == 0 else { return false }
      }
      for ii in 10...11 {
        guard $0[ii] == 0xFF else { return false }
      }
      return true
    }
  }
  
  /// Returns IPv4Address, or `nil` if the instance is `.v6` and is not IPv4-mapped.
  public var v4Address: IPAddress? {
    if case .v4 = self { return self }
    guard self.isIPv4Mapped else { return nil }
    return _withUnsafeBufferPointer { .v4($0[12], $0[13], $0[14], $0[15]) }
  }
}

extension IPAddress: Hashable {
  public static func ==(lhs:IPAddress, rhs:IPAddress) -> Bool {
    switch (lhs, rhs) {
    case (.v4, .v4), (.v6, .v6):
      return lhs._withUnsafeBufferPointer { (lp) -> Bool in
        return rhs._withUnsafeBufferPointer { (rp) -> Bool in
          assert(lp.count == rp.count)
          for ii in 0..<lp.count {
            if lp[ii] != rp[ii] { return false }
          }
          return true
        }
      }
    case (.v4, .v6):
      guard let mapped = rhs.v4Address else { return false }
      return lhs == mapped
    case (.v6, .v4):
      guard let mapped = lhs.v4Address else { return false }
      return mapped == rhs
    }
  }
  
  public func hash(into hasher:inout Hasher) {
    if case .v6 = self, let mapped = self.v4Address {
      mapped.hash(into: &hasher)
    }
    
    _withUnsafeBufferPointer {
      for ii in 0..<$0.count {
        hasher.combine($0[ii])
      }
    }
  }
}

/// Work with CIPAddress
extension IPAddress {
  private var _cIPAddress: CIPAddress {
    switch self {
    case .v4(let b0, let b1, let b2, let b3):
      return CIPv4Address((b0, b1, b2, b3))
    case .v6(let b0, let b1, let  b2, let  b3, let  b4, let  b5, let  b6, let  b7,
             let b8, let b9, let b10, let b11, let b12, let b13, let b14, let b15):
      return CIPv6Address((b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15))
    }
  }
  internal var _cIPSocketAddress: CIPSocketAddress {
    switch self {
    case .v4:
      return CIPv4SocketAddress(ipAddress:self._cIPAddress as! CIPv4Address)!
    case .v6:
      return CIPv6SocketAddress(ipAddress:self._cIPAddress as! CIPv6Address)!
    }
  }
}

extension IPAddress: CustomStringConvertible {
  public var description: String {
    return self._cIPAddress.description
  }
}
