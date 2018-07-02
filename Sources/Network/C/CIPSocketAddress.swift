/***************************************************************************************************
 CIPSocketAddress.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
/// Protocol for `CIPv4SocketAddress`(a.k.a. `sockaddr_in`) and `CIPv6SocketAddress`(a.k.a. `sockaddr_in6`)
public protocol CIPSocketAddress: CSocketAddressStructure {
  // var size: Int { get }
  // var family: CSocketAddressFamily { get }
  var port: CSocketPortNumber { get }
  var ipAddress: CIPAddress { get }
  init?(ipAddress:CIPAddress, port:CSocketPortNumber)
}

