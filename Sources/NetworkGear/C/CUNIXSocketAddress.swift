/* *************************************************************************************************
 CUNIXSocketAddress.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import CNetworkGear

extension CUNIXSocketAddress: CSocketAddressStructure {
  public private(set) var size: CSocketAddressSize {
    get {
      return withUnsafePointer(to: self) { CNWGUNIXSocketAddressSizeOf($0) }
    }
    set {
      #if !os(Linux)
      self.sun_len = newValue
      #endif
    }
  }
  
  public private(set) var family: CSocketAddressFamily {
    get {
      return CSocketAddressFamily(rawValue:self.sun_family) // AF_UNIX or AF_LOCAL
    }
    set {
      self.sun_family = newValue.rawValue
    }
  }
}

extension CUNIXSocketAddress {
  public var path: String {
    get {
      let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(cNWGUNIXSocketAddressPathLength))
      defer { buffer.deallocate() }

      withUnsafePointer(to: self, { CNWGUNIXSocketAddressGetPath($0, buffer) })
      return String(cString: buffer)
    }
    set {
      guard withUnsafeMutablePointer(to: &self, { CNWGUNIXSocketAddressSetPath($0, newValue) }) else {
        fatalError("Unxpected path for \(Self.self)")
      }
    }
  }
  
  public init?(path:String) {
    self.init()

    guard withUnsafeMutablePointer(to: &self, { CNWGUNIXSocketAddressSetPath($0, path) }) else {
      return nil
    }
    self.size = CSocketAddressSize(MemoryLayout<CUNIXSocketAddress>.size)
    self.family = .unix
  }
}

