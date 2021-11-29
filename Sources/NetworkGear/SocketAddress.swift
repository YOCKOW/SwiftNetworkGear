/***************************************************************************************************
 SocketAddress.swift
   © 2018, 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

@_exported import _NGCExtensions

///
/**

# SocketAddress
Wrapper class for `CSocketAddress`.
This class is necessary because `CSocketAddress()` or `sockaddr()` may allocate only insufficient memory space...
 
*/
///
public class SocketAddress {
  private var _size: Int
  private var _pointer: UnsafeMutableRawPointer
  private var _boundPointer: UnsafeMutablePointer<CSocketAddress> {
    return self._pointer.assumingMemoryBound(to:CSocketAddress.self)
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
    self._size = Int(pointer.pointee.size)
    self._pointer = UnsafeMutableRawPointer.allocate(byteCount:self._size,
                                                     alignment:MemoryLayout<Int8>.alignment)
    self._pointer.copyMemory(from:UnsafeRawPointer(pointer), byteCount:self._size)
  }
  
  /// Returns the actual size of `sockaddr_*`
  public var size: CSocketAddressSize {
    return self._boundPointer.pointee.size
  }
  
  /// Returns the family of `sockaddr_*`
  public var family: CSocketAddressFamily {
    return self._boundPointer.pointee.family
  }
  
  public var cSocketAddress: CSocketAddressStructure {
    let pointer = self._boundPointer
    let family = pointer.pointee.family
    if family == .unix {
      return pointer.withMemoryRebound(to: CUNIXSocketAddress.self, capacity:1) {
        return $0.pointee
      }
    } else if family == .ipv4 {
      return pointer.withMemoryRebound(to: CIPv4SocketAddress.self, capacity:1) {
        return $0.pointee
      }
    } else if family == .ipv6 {
      return pointer.withMemoryRebound(to: CIPv6SocketAddress.self, capacity:1) {
        return $0.pointee
      }
    } else {
      fatalError("Unimplemented family: \(family)")
    }
  }
}
