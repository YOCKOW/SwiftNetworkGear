/***************************************************************************************************
 CSocketAddressStructure.swift
   © 2017-2018,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import CNetworkGear

/// Protocol for `sockaddr_*`
public protocol CSocketAddressStructure {
  var size: CSocketAddressSize { get }
  var family: CSocketAddressFamily { get }
}
