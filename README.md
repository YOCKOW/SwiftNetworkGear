# What is `SwiftNetworkGear`?

`SwiftNetworkGear` will provide various functions about network.
It was originally written as a part of [SwiftCGIResponder](https://github.com/YOCKOW/SwiftCGIResponder).

# Requirements

- Swift 5
- macOS(>=10.15) or Linux

## Dependencies

![Dependencies](./dependencies.svg)


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

# License

MIT License.  
See "LICENSE.txt" for more information.
