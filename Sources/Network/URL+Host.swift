/***************************************************************************************************
 URL+Host.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/
 
import Foundation

extension URL {
  /// Wraps host component of `URL`.
  public struct Host {
    fileprivate enum _Host {
      case ipAddress(IPAddress)
      case domain(Domain)
      case string(String)
      
      /// First, check whether `string` can be parsed as an IP address or not.
      /// If it is not an IP address, check whether `string` can be parsed as a domain name or not.
      /// If it is not even a domain name, just hold it as a string.
      fileprivate init(string:String) {
        if string.hasPrefix("[") && string.hasSuffix("]") {
          let si = string.index(after:string.startIndex)
          let ei = string.index(before:string.endIndex)
          if let ip = IPAddress(string:String(string[si..<ei])) {
            self = .ipAddress(ip)
          } else {
            self = .string(string)
          }
        } else if let ip = IPAddress(string:string) {
          self = .ipAddress(ip)
        } else if let domain = Domain(string, options:.loose) {
          self = .domain(domain)
        } else {
          self = .string(string)
        }
      }
    }
    
    private var _host:_Host
    
    /// Initialize an instance with string
    public init(string:String) {
      self._host = _Host(string:string)
    }
    
    /// Returns `_host` is `.string` or not.
    internal var isString: Bool {
      switch self._host {
      case .string: return true
      default: return false
      }
    }
    
    /// A Boolean value that indicates whether the host is IP address or not.
    public var isIPAddress: Bool {
      switch self._host {
      case .ipAddress: return true
      default: return false
      }
    }
  }
}

extension URL {
  /// Returns an instance of `URL.Host` created from `var host: String?`
  public var hostComponent: URL.Host? {
    guard let host = self.host else { return nil }
    return Host(string:host)
  }
}

extension URL.Host._Host: Hashable {
  fileprivate static func ==(lhs:URL.Host._Host, rhs:URL.Host._Host) -> Bool {
    switch (lhs, rhs) {
    case (.ipAddress(let lIP), .ipAddress(let rIP)): return lIP == rIP
    case (.domain(let lDomain), .domain(let rDomain)): return lDomain == rDomain
    case (.string(let lStr), .string(let rStr)): return lStr == rStr
    default: return false
    }
  }
  fileprivate var hashValue: Int {
    switch self {
    case .ipAddress(let ip): return ip.hashValue
    case .domain(let domain): return domain.hashValue
    case .string(let string): return string.hashValue
    }
  }
}

extension URL.Host: Hashable {
  public static func ==(lhs:URL.Host, rhs:URL.Host) -> Bool {
    return lhs._host == rhs._host
  }
  
  public var hashValue: Int {
    return self._host.hashValue
  }
}

extension URL.Host._Host: CustomStringConvertible {
  fileprivate var description: String {
    switch self {
    case .ipAddress(let ip):
      switch ip {
      case .v4: return ip.description
      case .v6: return "[\(ip.description)]"
      }
    case .domain(let domain): return domain.description
    case .string(let string): return string
    }
  }
}

extension URL.Host: CustomStringConvertible {
  public var description: String {
    return self._host.description
  }
}

extension URL.Host._Host {
  fileprivate func _domainMatches(_ another:URL.Host._Host) -> Bool {
    switch (self, another) {
    case (.ipAddress, _), (_, .ipAddress):
      return false
    case (.domain(let myDomain), .domain(let anotherDomain)):
      return myDomain.domainMatches(anotherDomain)
    case (.string(let myString), .string(let anotherString)):
      return myString == anotherString || myString.hasSuffix(".\(anotherString)")
    default:
      return URL.Host._Host.string(self.description)._domainMatches(
        URL.Host._Host.string(another.description)
      )
    }
  }
}

extension URL.Host {
  public func domainMatches(_ another:URL.Host) -> Bool {
    return self._host._domainMatches(another._host)
  }
}
