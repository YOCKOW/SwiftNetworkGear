/***************************************************************************************************
 URL+IDNA.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

import Foundation

extension URL {
  /// Initialize `URL` with an international string such as "https://にっぽん。ＪＰ/☕︎.cgi?杯=2"
  /// - parameter internationalString: A string containing non-ASCII characters.
  /// - returns: If `string` can be parsed, an instance of `URL` is returned, otherwise `nil`.
  public init?(internationalString string:String) {
    // Scheme
    guard let rangeOfColonSlashSlash = string.range(of:"://") else { return nil }
    let scheme_raw = string[string.startIndex..<rangeOfColonSlashSlash.lowerBound]
    let scheme_normalized = scheme_raw.precomposedStringWithCompatibilityMapping
    let scheme = scheme_normalized.lowercased()
    if scheme.isEmpty { return nil }
    
    let indexOfFirstSlashAfterScheme: String.Index? =
      string.range(of:"/", range:rangeOfColonSlashSlash.upperBound..<string.endIndex)?.lowerBound
    
    // "user:password@host:port/path?query#fragment"
    // -> "user:password@host:port", "/path?query#fragment"
    let (authHostPort, pathQueryFragment) = ({ () -> (Substring, Substring) in
      let start = rangeOfColonSlashSlash.upperBound
      let idx = (indexOfFirstSlashAfterScheme != nil) ? indexOfFirstSlashAfterScheme! : string.endIndex
      return (string[start..<idx], string[idx..<string.endIndex])
    })()
    
    // "user:password@host:port"
    // -> "user:password", "host:port"
    let (auth, hostPort) = ({ (ahp:Substring) -> (Substring?, Substring) in
      if let rangeOfAtSign = ahp.range(of:"@") {
        let rangeOfAuth = ahp.startIndex..<rangeOfAtSign.lowerBound
        let rangeOfHostPort = rangeOfAtSign.upperBound..<ahp.endIndex
        return (ahp[rangeOfAuth], ahp[rangeOfHostPort])
      } else {
        return (nil, ahp)
      }
    })(authHostPort)
    
    // "user:password"
    // -> "user", "passsword"
    let (user, password):(Substring?, Substring?) = (auth == nil) ? (nil, nil) : ({
      if let rangeOfColon = $0.range(of:":") {
        let rangeOfUser = $0.startIndex..<rangeOfColon.lowerBound
        let rangeOfPassword = rangeOfColon.upperBound..<$0.endIndex
        return ($0[rangeOfUser], $0[rangeOfPassword])
      } else {
        return ($0, nil)
      }
    })(auth!)
    if user != nil {
      for scalar in user!.unicodeScalars {
        guard UnicodeScalarSet.urlUserAllowed.contains(scalar) else { return nil }
      }
    }
    if password != nil {
      for scalar in password!.unicodeScalars {
        guard UnicodeScalarSet.urlPasswordAllowed.contains(scalar) else { return nil }
      }
    }
    
    // "host:port"
    // -> "host", "port"
    let (host, port) = ({ (hp:Substring) -> (Substring, Substring?) in
      if let rangeOfLastColon = hp.range(of:":", options:.backwards) {
        let rangeOfHost = hp.startIndex..<rangeOfLastColon.lowerBound
        let rangeOfPort = rangeOfLastColon.upperBound..<hp.endIndex
        return (hp[rangeOfHost], hp[rangeOfPort])
      } else {
        return (hp, nil)
      }
    })(hostPort)
    if port != nil {
      guard let _ = UInt16(port!) else { return nil }
    }
    
    // "/path?query#fragment"
    // -> "/path?query", "fragment"
    let (pathQuery, fragment) = ({ (pqf:Substring) -> (Substring, Substring?) in
      if let rangeOfNumberSign = pqf.range(of:"#") {
        let rangeOfPathQuery = pqf.startIndex..<rangeOfNumberSign.lowerBound
        let rangeOfFragment = rangeOfNumberSign.upperBound..<pqf.endIndex
        return (pqf[rangeOfPathQuery], pqf[rangeOfFragment])
      } else {
        return (pqf, nil)
      }
    })(pathQueryFragment)
    
    // "/path?query"
    // -> "/path", "query"
    let (path, query) = ({ (pq:Substring) -> (Substring, Substring?) in
      if let rangeOfQuestionMark = pq.range(of:"?") {
        let rangeOfPath = pq.startIndex..<rangeOfQuestionMark.lowerBound
        let rangeOfQuery = rangeOfQuestionMark.upperBound..<pq.endIndex
        return (pq[rangeOfPath], pq[rangeOfQuery])
      } else {
        return (pq, nil)
      }
    })(pathQuery)
    
    // -----
    // Let's reconstruct URL.
    // -----
    var urlString = scheme + "://"
    
    // user & password
    if user != nil {
      urlString += user!
      if password != nil {
        urlString += ":" + password!
      }
      urlString += "@"
    }
    
    // host
    let hostComponent = URL.Host(string:String(host))
    if hostComponent.isString { return nil }
    urlString += hostComponent.description
    
    // port
    if port != nil { urlString += ":" + port! }
    
    // path
    guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters:.urlPathAllowed) else {
      return nil
    }
    urlString += encodedPath
    
    // query
    if query != nil {
      guard let encodedQuery = query!.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed) else {
        return nil
      }
      urlString += "?" + encodedQuery
    }
    
    // fragment
    if fragment != nil {
      guard let encodedFragment = fragment!.addingPercentEncoding(withAllowedCharacters:.urlFragmentAllowed) else {
        return nil
      }
      urlString += "#" + encodedFragment
    }
    
    self.init(string:urlString)
  }
}
