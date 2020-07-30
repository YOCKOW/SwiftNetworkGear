/* *************************************************************************************************
 CIPv6Address.swift
   © 2017-2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CoreFoundation
import Foundation

extension CIPv6Address: CIPAddress {
  public static let size: Int = 16
  
  public typealias Address = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                              UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
  
  public var address: Address {
    get {
      #if !os(Linux)
      return self.__u6_addr.__u6_addr8
      #else
      return self.__in6_u.__u6_addr8
      #endif
    }
    set {
      #if !os(Linux)
      self.__u6_addr.__u6_addr8 = newValue
      #else
      self.__in6_u.__u6_addr8 = newValue
      #endif
    }
  }
  
  public static func ==(lhs: CIPv6Address, rhs: CIPv6Address) -> Bool {
    return lhs.withUnsafeBufferPointer { lhsPointer -> Bool in
      return rhs.withUnsafeBufferPointer { rhsPointer -> Bool in
        for ii in 0..<CIPv6Address.size {
          guard lhsPointer[ii] == rhsPointer[ii] else { return false }
        }
        return true
      }
    }
  }
  
  /// Initialize with 16 `UInt8`s.
  public init(_ bytes: Address) {
    self.init()
    self.address = bytes
  }
  
  /// Initialized with `string` such as "1234::ABCD".
  /// Returns `nil` if the string is not valid for IPv6 Address.
  public init?(_ string: String) {
    self.init()
    guard inet_pton(AF_INET6, string, &self) == 1 else { return nil }
  }
  
  public var description: String {
    var address_p = UnsafeMutablePointer<CChar>.allocate(capacity:Int(INET6_ADDRSTRLEN))
    defer { address_p.deallocate() }
    
    var myself = self
    guard inet_ntop(AF_INET6, &myself.address, address_p, CSocketRelatedSize(INET6_ADDRSTRLEN)) != nil else {
      fatalError("Failed to convert IP address to String")
    }
    return String(utf8String:address_p)!
  }
}
