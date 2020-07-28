/* *************************************************************************************************
 CIPAddress.swift
   © 2017-2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
/// A type that can represent an IP Address in C.
///
/// Do not declare new conformances to `CIPAddress`.
/// Only the `CIPv4Address`(a.k.a. `in_addr`) and `CIPv6Address`(a.k.a. `in6_addr`) types
/// in this library are valid conforming types.
public protocol CIPAddress: LosslessStringConvertible, Equatable {
  associatedtype Address
  
  /// The address in byte format with network byte order.
  var address: Address { get set }
  
  /// Calls the given closure with a pointer to the address in byte format.
  mutating func withUnsafeMutableBufferPointer<Result>(_ body: (inout UnsafeMutableBufferPointer<UInt8>) throws -> Result) rethrows -> Result
  
  /// Calls the given closure with a pointer to the address in byte format.
  func withUnsafeBufferPointer<Result>(_ body: (UnsafeBufferPointer<UInt8>) throws -> Result) rethrows -> Result
  
  static var size: Int { get }
  
  init()
  
  /// Initialize the address in byte format.
  init?<C>(_ bytes: C) where C: Collection, C.Element == UInt8
}

extension CIPAddress {
  public mutating func withUnsafeMutableBufferPointer<Result>(_ body: (inout UnsafeMutableBufferPointer<UInt8>) throws -> Result) rethrows -> Result {
    return try withUnsafeMutablePointer(to: &self.address) {
      return try $0.withMemoryRebound(to: UInt8.self, capacity: Self.size) {
        var pointer = UnsafeMutableBufferPointer<UInt8>(start: $0, count: Self.size)
        return try body(&pointer)
      }
    }
  }
  
  public func withUnsafeBufferPointer<Result>(_ body: (UnsafeBufferPointer<UInt8>) throws -> Result) rethrows -> Result {
    return try withUnsafePointer(to: self.address) {
      return try $0.withMemoryRebound(to: UInt8.self, capacity: Self.size) {
        return try body(UnsafeBufferPointer<UInt8>(start: $0, count: Self.size))
      }
    }
  }
  
  public init?<C>(_ bytes: C) where C: Collection, C.Element == UInt8 {
    guard bytes.count == Self.size else { return nil }
    self.init()
    self.withUnsafeMutableBufferPointer {
      for (ii, byte) in bytes.enumerated() {
        $0[ii] = byte
      }
    }
  }
}

// MARK: - Deprecated APIs
extension CIPAddress {
  @available(*, deprecated, message: "Use `func withUnsafeBufferPointer` instead.")
  public var bytes: [UInt8] {
    get {
      return self.withUnsafeBufferPointer { Array<UInt8>($0) }
    }
    set(newBytes) {
      self.withUnsafeMutableBufferPointer {
        precondition($0.count == newBytes.count, "Incorrect length of bytes.")
        for (ii, byte) in newBytes.enumerated() {
          $0[ii] = byte
        }
      }
    }
  }
  
  @available(*, deprecated, renamed: "init(_:)")
  public init?<S>(string: S) where S: StringProtocol {
    self.init(String(string))
  }
}
