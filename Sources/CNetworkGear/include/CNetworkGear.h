/* *************************************************************************************************
 CNetworkGear/CNetworkGear.h
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#ifndef yCNetworkGear_H
#define yCNetworkGear_H
#include <stdint.h>
#include <netinet/in.h>

// MARK: - Common Types

typedef uint8_t   CSocketAddressSize;
typedef in_port_t CSocketPortNumber;
typedef uint32_t  CIPv6FlowIdentifier;
typedef uint32_t  CIPv6ScopeIdentifier;

typedef socklen_t CSocketRelatedSize;

typedef struct sockaddr     CSocketAddress;
typedef struct sockaddr_in  CIPv4SocketAddress;
typedef struct in_addr      CIPv4Address;
typedef struct sockaddr_in6 CIPv6SocketAddress;
typedef struct in6_addr     CIPv6Address;
typedef struct sockaddr_un  CUNIXSocketAddress;

typedef struct addrinfo CSocketAddressInformation;


// MARK: - Shim Types

typedef enum {
  cNWGStreamSocket = SOCK_STREAM,
  cNWGDatagramSocket = SOCK_DGRAM,
  cNWGRawProtocolSocket = SOCK_RAW,
  cNWGReliablyDeliveredMessageSocket = SOCK_RDM,
  cNWGSequencedPacketStreamSocket = SOCK_SEQPACKET,
} CNWGSocketType;


#endif
