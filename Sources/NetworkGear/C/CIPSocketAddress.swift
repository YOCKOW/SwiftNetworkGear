/* *************************************************************************************************
 CIPSocketAddress.swift
   © 2017-2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
/// A type that can represent a socket address in C.
///
/// Do not declare new conformances to `CIPAddress`.
/// Only the `CIPv4SocketAddress`(a.k.a. `sockaddr_in`) and `CIPv6SocketAddress`(a.k.a. `sockaddr_in6`) types
/// in this library are valid conforming types.
public protocol CIPSocketAddress: CSocketAddressStructure {
  associatedtype ConcreteIPAddress: CIPAddress
  
  var port: CSocketPortNumber { get }
  var ipAddress: ConcreteIPAddress { get }
  init?(ipAddress: ConcreteIPAddress, port: CSocketPortNumber)
}

