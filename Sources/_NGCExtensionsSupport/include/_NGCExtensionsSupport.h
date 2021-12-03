/* *************************************************************************************************
 _NGCExtensionsSupport.h
   © 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// This C-module exists to work around SR-15532.
// See https://bugs.swift.org/browse/SR-15532

/*

# STRUCTURES

+-----------+----------------+------------------+----------------+------------------------+-------------+----------------------------+
|           |sockaddr        |sockaddr_in       |in_addr         |sockaddr_in6            |in6_addr     |size on general OS          |
+-----------+----------------+------------------+----------------+------------------------+-------------+----------------------------+
|__uint8_t  |sa_len          |sin_len           |                |sin6_len                |             |(1 byte; not exist on Linux)|
|sa_family_t|sa_family       |sin_family        |                |sin6_family             |             |(1 byte)                    |
|           |char sa_data[14]|in_port_t sin_port|                |sin6_port               |             |(2 bytes)                   |
|           |                |in_addr sin_addr  |in_addr_t s_addr|__uint32_t sin6_flowinfo|             |(4 bytes)                   |
|           |                |                  |                |in6_addr sin6_addr      |union s6_addr|(16 bytes)                  |
|           |                |                  |                |__uint32_t sin6_scope_id|             |(4 bytes)                   |
+-----------+----------------+------------------+----------------+------------------------+-------------+----------------------------+

Other structures (i.g. `struct sockaddr_un`) are also available on some OS.

*/

#ifndef NGCExtensionsSupport_H
#define NGCExtensionsSupport_H

#include <stdint.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>

typedef uint8_t       _NGCESocketAddressSize;
typedef in_port_t     _NGCESocketPortNumber;
typedef in_addr_t     _NGCEIPv4AddressBytes;
typedef unsigned char _NGCEIPv6AddressBytes[16];
typedef uint32_t      _NGCEIPv6FlowIdentifier;
typedef uint32_t      _NGCEIPv6ScopeIdentifier;
typedef socklen_t     _NGCESocketRelatedSize;
typedef sa_family_t   _NGCESocketAddressFamily;
typedef int           _NGCEAddressInformationFlag;
typedef int           _NGCESocketProtocolFamily;
typedef int           _NGCESocketType;
typedef struct sockaddr     _NGCESocketAddress;
typedef struct sockaddr_in  _NGCEIPv4SocketAddress;
typedef struct in_addr      _NGCEIPv4Address;
typedef struct sockaddr_in6 _NGCEIPv6SocketAddress;
typedef struct in6_addr     _NGCEIPv6Address;
typedef struct sockaddr_un  _NGCEUNIXSocketAddress;
typedef struct addrinfo     _NGCESocketAddressInformation;

extern _NGCESocketRelatedSize _kNGCEIPv4AddressStringLength;
extern _NGCESocketRelatedSize _kNGCEIPv6AddressStringLength;

extern _NGCESocketAddressFamily _kNGCESocketAddressFamilyIPv4;
extern _NGCESocketAddressFamily _kNGCESocketAddressFamilyIPv6;
extern _NGCESocketAddressFamily _kNGCESocketAddressFamilyUNIX;
extern _NGCESocketAddressFamily _kNGCESocketAddressFamilyUnspecified;

extern _NGCEAddressInformationFlag _kNGCEAddressInformationFlagPassive;
extern _NGCEAddressInformationFlag _kNGCEAddressInformationFlagCanonicalName;
extern _NGCEAddressInformationFlag _kNGCEAddressInformationFlagNumericHost;
extern _NGCEAddressInformationFlag _kNGCEAddressInformationFlagV4Mapped;
extern _NGCEAddressInformationFlag _kNGCEAddressInformationFlagAll;
extern _NGCEAddressInformationFlag _kNGCEAddressInformationFlagAddressConfiguration;
extern _NGCEAddressInformationFlag _kNGCEAddressInformationFlagNumericService;

extern _NGCESocketProtocolFamily _kNGCESocketProtocolFamilyTCP;
extern _NGCESocketProtocolFamily _kNGCESocketProtocolFamilyUDP;

extern _NGCESocketType _kNGCESocketTypeStream;
extern _NGCESocketType _kNGCESocketTypeDatagram;
extern _NGCESocketType _kNGCESocketTypeRaw;
extern _NGCESocketType _kNGCESocketTypeReliablyDeliveredMessage;
extern _NGCESocketType _kNGCESOcketTypeSequencedPacket;


#ifdef __APPLE__
#include <CoreFoundation/CFByteOrder.h>
static inline uint16_t _NGCESwapInt16BigToHost(uint16_t integer) {
  return CFSwapInt16BigToHost(integer);
}
static inline uint16_t _NGCESwapInt16HostToBig(uint16_t integer) {
  return CFSwapInt16HostToBig(integer);
}
static inline uint32_t _NGCESwapInt32BigToHost(uint32_t integer) {
  return CFSwapInt32BigToHost(integer);
}
static inline uint32_t _NGCESwapInt32HostToBig(uint32_t integer) {
  return CFSwapInt32HostToBig(integer);
}
#else
#include <endian.h>
static inline uint16_t _NGCESwapInt16BigToHost(uint16_t integer) {
  return be16toh(integer);
}
static inline uint16_t _NGCESwapInt16HostToBig(uint16_t integer) {
  return htobe16(integer);
}
static inline uint32_t _NGCESwapInt32BigToHost(uint32_t integer) {
  return be32toh(integer);
}
static inline uint32_t _NGCESwapInt32HostToBig(uint32_t integer) {
  return htobe32(integer);
}
#endif

// MARK: - Address ⇄ String

static inline
const char * _Nullable _NGCEAddressToString(
  _NGCESocketAddressFamily family,
  const void * _Nonnull source,
  char * _Nonnull destination,
  _NGCESocketRelatedSize size
) {
  return inet_ntop((int)family, source, destination, size);
}

static inline
int _NGCEStringToAddress(
  _NGCESocketAddressFamily family,
  const char * _Nonnull source,
  void * _Nonnull destination
) {
  return inet_pton((int)family, source, destination);
}

// MARK: - s6_addr: cannot be used from Swift...

static inline
const _NGCEIPv6AddressBytes * _Nonnull const _NGCEGetIPv6AddressBytes(const _NGCEIPv6Address * _Nonnull const address) {
  return &address->s6_addr;
}

static inline
void _NGCESetIPv6AddressBytes(_NGCEIPv6Address * _Nonnull address, const _NGCEIPv6AddressBytes _Nonnull bytes) {
  memcpy(address->s6_addr, bytes, sizeof(_NGCEIPv6AddressBytes));
}


#endif // NGCExtensionsSupport_H
