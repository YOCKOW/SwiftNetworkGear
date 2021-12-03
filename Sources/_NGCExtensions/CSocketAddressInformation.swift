/***************************************************************************************************
 CSocketAddressInformation.swift
   © 2017-2018, 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import _NGCExtensionsSupport

/// Extend `CSocketAddressInformation` (a.k.a. `addrinfo`)
extension CSocketAddressInformation {
  public struct Options: OptionSet {
    public let rawValue: CInt
    public init(rawValue: CInt) {
      self.rawValue = rawValue
    }
    
    public static let none = Options([])
    public static let passive = Options(rawValue: _kNGCEAddressInformationFlagPassive)
    public static let requestForCanonicalName = Options(rawValue: _kNGCEAddressInformationFlagCanonicalName)
    public static let disallowHostNameResolution = Options(rawValue: _kNGCEAddressInformationFlagNumericHost)
    public static let acceptIPv4MappedAddress = Options(rawValue: _kNGCEAddressInformationFlagV4Mapped)
    public static let includeBothIPv4MappedAndIPv6Address = Options(rawValue: _kNGCEAddressInformationFlagAll)
    public static let useHostConfiguration = Options(rawValue: _kNGCEAddressInformationFlagAddressConfiguration)
    public static let disallowServiceNameResolution = Options(rawValue: _kNGCEAddressInformationFlagNumericService)
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
  public var socketAddress: CSocketAddressStructure? {
    get {
      guard let pointer = self.ai_addr  else { return nil }
      return CSocketAddress.actualSocketAddress(for:UnsafePointer(pointer))
    }
  }
}


