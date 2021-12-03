/* *************************************************************************************************
 CIPv6Address.swift
   © 2017-2018, 2020-2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import _NGCExtensionsSupport

extension CIPv6Address: CIPAddress {
  public static let size: Int = 16
  
  public typealias Address = CIPv6AddressBytes
  
  public var address: Address {
    get {
      return withUnsafePointer(to: self) {
        return _NGCEGetIPv6AddressBytes($0).pointee
      }
    }
    set {
      withUnsafePointer(to: newValue) {
        $0.withMemoryRebound(to: UInt8.self, capacity: Self.size) { (newValuePointer) in
          withUnsafeMutablePointer(to: &self) {
            _NGCESetIPv6AddressBytes($0, newValuePointer)
          }
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
    guard _NGCEStringToAddress(_kNGCESocketAddressFamilyIPv6, string, &self) == 1 else {
      return nil
    }
  }
  
  public var description: String {
    let address_p = UnsafeMutablePointer<CChar>.allocate(capacity: Int(_kNGCEIPv6AddressStringLength))
    defer { address_p.deallocate() }

    return withUnsafePointer(to: self.address) {
      guard let _ = _NGCEAddressToString(
        _kNGCESocketAddressFamilyIPv6,
        $0,
        address_p,
        _kNGCEIPv6AddressStringLength
      ) else {
        fatalError("Failed to convert IP address to String")
      }
      return String(utf8String: address_p)!
    }
  }
}
