# What is `SwiftNetworkGear`?

`SwiftNetworkGear` will provide various functions about network.
It was originally written as a part of [SwiftCGIResponder](https://github.com/YOCKOW/SwiftCGIResponder).

# Requirements

- Swift >=6.2
- macOS(>=13) or Linux


## Dependencies

<!-- SWIFT PACKAGE DEPENDENCIES MERMAID START -->
```mermaid
---
title: NetworkGear Dependencies
---
flowchart TD
  swiftbootstring(["Bootstring<br>@1.2.0"])
  swiftnetworkgear["NetworkGear"]
  swiftpublicsuffix(["PublicSuffix<br>@2.4.21"])
  swiftranges(["Ranges<br>@4.0.2"])
  swifttemporaryfile(["TemporaryFile<br>@5.0.0"])
  swiftunicodesupplement(["UnicodeSupplement<br>@2.0.1"])
  yswiftextensions(["yExtensions<br>@2.2.1"])

  click swiftbootstring href "https://github.com/YOCKOW/SwiftBootstring.git"
  click swiftpublicsuffix href "https://github.com/YOCKOW/SwiftPublicSuffix.git"
  click swiftranges href "https://github.com/YOCKOW/SwiftRanges.git"
  click swifttemporaryfile href "https://github.com/YOCKOW/SwiftTemporaryFile.git"
  click swiftunicodesupplement href "https://github.com/YOCKOW/SwiftUnicodeSupplement.git"
  click yswiftextensions href "https://github.com/YOCKOW/ySwiftExtensions.git"

  swiftnetworkgear ----> swiftbootstring
  swiftnetworkgear ----> swiftpublicsuffix
  swiftnetworkgear ----> swiftranges
  swiftnetworkgear --> swifttemporaryfile
  swiftnetworkgear --> swiftunicodesupplement
  swiftnetworkgear --> yswiftextensions
  swifttemporaryfile ----> swiftranges
  swifttemporaryfile --> yswiftextensions
  swiftunicodesupplement ----> swiftranges
  yswiftextensions ----> swiftranges
  yswiftextensions --> swiftunicodesupplement


```
<!-- SWIFT PACKAGE DEPENDENCIES MERMAID END -->


# Usage

```Swift
import NetworkGear
import Foundation

// DNS Lookup
Domain("GitHub.com")!.ipAddresses
//// -> [192.30.255.112, 192.30.255.113]

// DNS Reverse Lookup
IPAddress(string:"192.30.255.112")!.domain!
//// -> lb-192-30-255-112-sea.github.com

// Punycode
Domain("www.日本.jp")!.description
//// -> www.xn--wgv71a.jp


// Extended URL
URL(internationalString:"https://USER:PASSWORD@にっぽん。ＪＰ:8080/☕︎.cgi?杯=2#MyCoffee")!
//// -> https://USER:PASSWORD@xn--j9jp9cue.jp:8080/%E2%98%95.cgi?%E6%9D%AF=2#MyCoffee

// Public Suffix
Domain("YOCKOW.jp")!.isPublicSuffix
//// -> false
Domain("YOCKOW.JP")!.publicSuffix!.description
//// -> jp
```

## `SimpleHTTPConnection`

There is a type named `SimpleHTTPConnection` that doesn't depend on `URLSession` but directly use
[libcurl](https://curl.se/libcurl/) as its backend.

```Swift
import NetworkGear

let url = URL(string: "https://httpbin.org/post")!
let connection = SimpleHTTPConnection(
  url: url,
  method: .post,
  requestHeader: [
    .contentLength(7),
    .contentType(.wwwFormURLEncoded),
  ],
  requestBody: .init(data: Data("foo=bar".utf8)),
  redirectStrategy: .noFollow
)
let response = try await connection.response()
let content = response.content
```

# License

MIT License.  
See "LICENSE.txt" for more information.
