/***************************************************************************************************
 CUNIXSocketAddress.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import Foundation

extension CUNIXSocketAddress: CSocketAddressStructure {
  public private(set) var size: CSocketAddressSize {
    get {
      #if !os(Linux)
      return self.sun_len
      #else
      return CSocketAddressSize(MemoryLayout<CUNIXSocketAddress>.size)
      #endif
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
  private var _pathLength: Int { return MemoryLayout.size(ofValue:self.sun_path) }
  
  private var _data: Data {
    get {
      var path = self.sun_path
      return withUnsafePointer(to:&path) {
        return Data(bytes:UnsafeRawPointer($0), count:self._pathLength)
      }
    }
    set(newData) {
      guard newData.count <= self._pathLength else { fatalError("Too long") }
      withUnsafeMutableBytes(of:&self.sun_path) {
        for ii in 0..<newData.count {
          $0[ii] = newData[ii]
        }
      }
    }
  }
  
  public var path: String {
    get {
      return String(data:self._data, encoding:.utf8)!
    }
    set {
      guard let data = newValue.data(using:.utf8) else { fatalError("Invalid String") }
      self._data = data
    }
  }
  
  public init?(path:String) {
    self.init()
    guard let data = path.data(using:.utf8), data.count <= self._pathLength else { return nil }
    self.size = CSocketAddressSize(MemoryLayout<CUNIXSocketAddress>.size)
    self.family = .unix
    self._data = Data(repeating:0, count:self._pathLength) // reset
    self._data = data
  }
}

