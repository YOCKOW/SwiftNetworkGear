/* *************************************************************************************************
 SocketAddress.swift
   © 2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CNetworkGear

///
/**

# SocketAddress
Wrapper class for `CSocketAddress`.
This class is necessary because `CSocketAddress()` or `sockaddr()` may allocate only insufficient memory space...
 
*/
///
public final class SocketAddress: @unchecked Sendable {
  private let _size: Int
  private let _pointer: UnsafeMutableRawPointer
  private var _boundPointer: UnsafePointer<CSocketAddress> {
    return UnsafePointer<CSocketAddress>(_pointer.assumingMemoryBound(to: CSocketAddress.self))
  }
  
  deinit {
    self._pointer.deallocate()
  }
  
  /// Initialize with `socketAddress` whose type is named `sockaddr_*` in C.
  public init<Address: CSocketAddressStructure>(socketAddress:Address) {
    self._size = Int(socketAddress.size)
    self._pointer = UnsafeMutableRawPointer.allocate(byteCount:self._size,
                                                     alignment:MemoryLayout<Int8>.alignment)
    self._pointer.bindMemory(to:type(of:socketAddress), capacity:1).pointee = socketAddress
  }
  
  internal init(_ pointer:UnsafeMutablePointer<CSocketAddress>) {
    self._size = Int(UnsafePointer<CSocketAddress>(pointer).size)
    self._pointer = UnsafeMutableRawPointer.allocate(byteCount:self._size,
                                                     alignment:MemoryLayout<Int8>.alignment)
    self._pointer.copyMemory(from:UnsafeRawPointer(pointer), byteCount:self._size)
  }
  
  /// Returns the actual size of `sockaddr_*`
  public var size: CSocketAddressSize {
    return _boundPointer.size
  }
  
  /// Returns the family of `sockaddr_*`
  public var family: CSocketAddressFamily {
    return _boundPointer.family
  }
  
  public var cSocketAddress: any CSocketAddressStructure {
    return _boundPointer.actualSocketAddress
  }
}
