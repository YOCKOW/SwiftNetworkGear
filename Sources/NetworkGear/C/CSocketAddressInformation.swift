/***************************************************************************************************
 CSocketAddressInformation.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CNetworkGear

/// Extend `CSocketAddressInformation` (a.k.a. `addrinfo`)
extension CSocketAddressInformation {
  public struct Options: OptionSet {
    public let rawValue:CInt
    public init(rawValue:CInt) { self.rawValue = rawValue }

    @inlinable
    public init(_ cFlags: CNWGSocketAddressInformationFlag) {
      self.rawValue = CInt(cFlags.rawValue)
    }

    public static let none = Options([])
    public static let passive = Options(cNWGAIFlagPassive)
    public static let canonicalNameRequest = Options(cNWGAIFlagCanonicalNameRequest)
    @available(*, deprecated, renamed: "canonicalNameRequest")
    public static let requestForCanonicalName = canonicalNameRequest
    public static let disallowHostnameResolution = Options(cNWGAIFlagDisallowHostnameResolution)
    @available(*, deprecated, renamed: "disallowHostnameResolution")
    public static let disallowHostNameResolution = Options(cNWGAIFlagDisallowHostnameResolution)
    public static let acceptIPv4MappedAddress = Options(cNWGAIFLagAcceptIPv4MappedAddress)
    public static let includeBothIPv4MappedAndIPv6Address = Options(cNWGAIFlagIncludeBothIPv4MappedAndIPv6Address)
    public static let useHostConfiguration = Options(cNWGAIFlagUseHostConfiguration)
    public static let disallowServiceNameResolution = Options(cNWGAIFlagDisallowServiceNameResolution)
  }
  
  public var options: Options {
    get { return Options(rawValue:self.ai_flags) }
    set { self.ai_flags = newValue.rawValue }
  }
  
  public var family: CSocketAddressFamily {
    get { return CSocketAddressFamily(rawValue:self.ai_family) }
    set { self.ai_family = CInt(newValue.rawValue) }
  }
  
  public var socketType: CSocketType {
    get { return CSocketType(rawValue:self.ai_socktype) }
    set { self.ai_socktype = CInt(newValue.rawValue) }
  }
  
  public var socketProtocol: CSocketProtocolFamily {
    get { return CSocketProtocolFamily(rawValue:self.ai_protocol) }
    set { self.ai_protocol = CInt(newValue.rawValue) }
  }
  
  public internal(set) var size: CSocketRelatedSize {
    get { return CSocketRelatedSize(self.ai_addrlen) }
    set { self.ai_addrlen = newValue }
  }
  
  public var canonicalName: String? {
    get {
      guard let pointer = self.ai_canonname else { return nil }
      return String(utf8String:UnsafePointer<CChar>(pointer))
    }
  }
  
  /// Returns the pointee of `.ai_next`, or nil if the pointer is null.
  public var next: CSocketAddressInformation? {
    get { return self.ai_next?.pointee }
  }
  
  /// Returns the pointee of `.ai_addr`, or nil if the pointer is null.
  public var socketAddress: (any CSocketAddressStructure)? {
    get {
      guard let pointer = self.ai_addr  else { return nil }
      return UnsafePointer<CSocketAddress>(pointer).actualSocketAddress
    }
  }
}


