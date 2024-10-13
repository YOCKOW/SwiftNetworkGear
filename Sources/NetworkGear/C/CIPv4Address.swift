/* *************************************************************************************************
 CIPv4Address.swift
   © 2017-2018,2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CNetworkGear

extension CNetworkGear.CIPv4Address: NetworkGear.CIPAddress {
  public static let size: Int = 4
  
  public typealias Address = CIPv4AddressBase
  
  public var address: Address {
    get {
      return self.s_addr
    }
    set {
      self.s_addr = newValue
    }
  }
  
  public static func ==(lhs: CIPv4Address, rhs: CIPv4Address) -> Bool {
    return lhs.address == rhs.address
  }
  
  /// Initialize with 4 `UInt8`s.
  public init(_ bytes: (UInt8, UInt8, UInt8, UInt8)) {
    self.init()
    self.withUnsafeMutableBufferPointer {
      $0[0] = bytes.0
      $0[1] = bytes.1
      $0[2] = bytes.2
      $0[3] = bytes.3
    }
  }
  
  /// Returns string such as "127.0.0.1"
  public var description: String {
    let address_p = UnsafeMutablePointer<CChar>.allocate(capacity: Int(cNWGIPv4AddressStringLength))
    defer { address_p.deallocate() }
    
    return withUnsafePointer(to: self.s_addr) {
      guard CNWGIPAddressToString(
        cNWGIPv4AddressFamily,
        $0,
        address_p,
        CSocketRelatedSize(cNWGIPv4AddressStringLength)
      ) != nil else {
        fatalError("Failed to convert IP address to String")
      }
      return String(utf8String: address_p)!
    }
  }
  
  /// Initialized with `string` such as "127.0.0.1".
  /// Returns `nil` if the string is not valid for IPv4 Address.
  public init?(_ string: String) {
    self.init()
    guard CNWGStringToIPAddress(cNWGIPv4AddressFamily, string, &self) == 1 else { return nil }
  }
}
