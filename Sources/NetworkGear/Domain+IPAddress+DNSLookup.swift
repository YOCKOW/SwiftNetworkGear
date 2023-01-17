/***************************************************************************************************
 Domain+IPAddress+DNSLookup.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

#if os(Linux)
import Glibc
#else
import Darwin
#endif

extension Domain {
  /// DNS Lookup
  public var ipAddresses:[IPAddress] {
    var results: [IPAddress] = []
    
    var hints = CSocketAddressInformation()
    hints.options = .none
    hints.family = .unspecified
    hints.socketType = .stream
    
    let results_pp = UnsafeMutablePointer<UnsafeMutablePointer<CSocketAddressInformation>?>.allocate(capacity:1)
    defer { results_pp.deallocate() }
    
    
    guard let domainName = self.addingPunycodeEncoding?.description else { return [] }
    
    guard getaddrinfo(domainName, "http", &hints, results_pp) == 0 else { return [] }
    defer { freeaddrinfo(results_pp.pointee) }
    
    var info: CSocketAddressInformation? = results_pp.pointee?.pointee // first one
    while true {
      if info == nil { break }
      defer { info = info!.next }
      
      guard let socketAddress = info!.socketAddress else { return [] }
      
      func __ipAddress() -> IPAddress? {
        switch socketAddress {
        case let cIPv4SockAddr as CIPv4SocketAddress:
          return IPAddress(cIPv4SockAddr.ipAddress)
        case let cIPv6SockAddr as CIPv6SocketAddress:
          return IPAddress(cIPv6SockAddr.ipAddress)
        default:
          return nil
        }
      }
      
      guard let ipAddress = __ipAddress() else { return [] }
      results.append(ipAddress)
    }
    
    return results
  }
}

extension IPAddress {
  /// DNS reverse lookup
  public var domain: Domain? {
    let domain_p = UnsafeMutablePointer<CChar>.allocate(capacity:Int(NI_MAXHOST))
    defer { domain_p.deallocate() }
    
    func __getNameInfo<T>(_ sockAddr: T) -> CInt where T: CIPSocketAddress {
      let size = CSocketRelatedSize(sockAddr.size)
      return withUnsafePointer(to: sockAddr) {
        let asSockAddr = UnsafeRawPointer($0).bindMemory(to: CSocketAddress.self, capacity: 2)
        return getnameinfo(asSockAddr, size,
                           domain_p, CSocketRelatedSize(NI_MAXHOST),
                           nil, 0, NI_NAMEREQD)
      }
    }
    
    let result = self._cIPv4SocketAddress.map({ __getNameInfo($0) }) ?? __getNameInfo(self._cIPv6SocketAddress!)
    guard result  == 0 else { return nil }
    guard let domain = String(utf8String:domain_p), !domain.isEmpty else { return nil }
    return Domain(domain, options:.loose)
  }
}
