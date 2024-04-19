# CNetworkGear

The reason why this module exists is to avoid some compiler's bugs such as [SR-15532](https://github.com/apple/swift/issues/57835), [SR-15586](https://github.com/apple/swift/issues/57889), and [SR-15822](https://github.com/apple/swift/issues/58096).

Tracking issue: [#36](https://github.com/YOCKOW/SwiftNetworkGear/issues/36).


# Implementation Note

This module wraps some structures in C related to network.
 
 ## structures in C


 |             |sockaddr          |sockaddr_in         |in_addr           |sockaddr_in6              |in6_addr       |size on general OS          |
 |-------------|------------------|--------------------|------------------|--------------------------|---------------|----------------------------|
 |`__uint8_t`  |`sa_len`          |`sin_len `          |                  |`sin6_len`                |               |(1 byte; not exist on Linux)|
 |`sa_family_t`|`sa_family `      |`sin_family`        |                  |`sin6_family`             |               |(1 byte)                    |
 |             |`char sa_data[14]`|`in_port_t sin_port`|                  |`sin6_port`               |               |(2 bytes)                   |
 |             |                  |`in_addr sin_addr`  |`in_addr_t s_addr`|`__uint32_t sin6_flowinfo`|               |(4 bytes)                   |
 |             |                  |                    |                  |`in6_addr sin6_addr`      |`union s6_addr`|(16 bytes)                  |
 |             |                  |                    |                  |`__uint32_t sin6_scope_id`|               |(4 bytes)                   |
 
 Other structures (i.g. `struct sockaddr_un`) are also available on some OS.
 
 ```c
 // Darwin
 struct in6_addr {
   union {
     __uint8_t   __u6_addr8[16];
     __uint16_t  __u6_addr16[8];
     __uint32_t  __u6_addr32[4];
   } __u6_addr;
 };
 #define s6_addr __u6_addr.__u6_addr8
 
 // Linux
 struct in6_addr {
   union {
     uint8_t  __u6_addr8[16];
     uint16_t __u6_addr16[8];
     uint32_t __u6_addr32[4];
   } __in6_u;
 }
 #define s6_addr __in6_u.__u6_addr8
 
 // NOTICE
 //// Cannot access `.s6_addr` directly from Swift on neither macOS nor Linux.
 ```
 
 There's also a structure named `addrinfo`:
 
 ```c
 struct addrinfo {
   int              ai_flags;
   int              ai_family;
   int              ai_socktype;
   int              ai_protocol;
   socklen_t        ai_addrlen;
   struct sockaddr *ai_addr;
   char            *ai_canonname;
   struct addrinfo *ai_next;
 };
 ```