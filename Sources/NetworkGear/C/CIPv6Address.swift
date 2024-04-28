/* *************************************************************************************************
 CIPv6Address.swift
   © 2017-2018,2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CNetworkGear

extension CIPv6Address: CIPAddress {
  public static let size: Int = 16
  
  public typealias Address = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                              UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
  
  public var address: Address {
    get {
      var address: Address = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
      withUnsafeMutableBytes(of: &address) { (addressPointer) in
        withUnsafePointer(to: self) { (selfPointer) in
          CNWGIPv6AddressGetBytes(
            selfPointer,
            addressPointer.assumingMemoryBound(to: UInt8.self).baseAddress!
          )
        }
      }
      return address
    }
    set {
      withUnsafePointer(to: newValue) { (newValuePointer) in
        withUnsafeMutablePointer(to: &self) { (selfPointer) in
          CNWGIPv6AddressSetBytes(selfPointer, newValuePointer)
        }
      }
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
    guard CNWGStringToIPAddress(cNWGIPv6AddressFamily, string, &self) == 1 else { return nil }
  }
  
  public var description: String {
    let address_p = UnsafeMutablePointer<CChar>.allocate(capacity: Int(cNWGIPv6AddressStringLength))
    defer { address_p.deallocate() }
    
    return withUnsafePointer(to: self.address) { (selfAddressPointer) -> String in
      guard CNWGIPAddressToString(
        cNWGIPv6AddressFamily,
        selfAddressPointer,
        address_p,
        CSocketRelatedSize(cNWGIPv6AddressStringLength)
      ) != nil else {
        fatalError("Failed to convert IP address to String")
      }
      return String(utf8String: address_p)!
    }
  }
}
