/***************************************************************************************************
 SocketAddress.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

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
    return CSocketAddress.actualSocketAddress(for:UnsafePointer(self._boundPointer))
  }
}
