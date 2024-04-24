/* *************************************************************************************************
 CNetworkGear/CNetworkGear.h
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#ifndef yCNetworkGear_H
#define yCNetworkGear_H
#include <stdbool.h>
#include <stdint.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/un.h>

// MARK: - Common Types

typedef uint8_t   CSocketAddressSize;
typedef in_port_t CSocketPortNumber;
typedef uint32_t  CIPv6FlowIdentifier;
typedef uint32_t  CIPv6ScopeIdentifier;

typedef sa_family_t CSocketAddressFamilyValue;
typedef socklen_t CSocketRelatedSize;

typedef struct sockaddr     CSocketAddress;
typedef struct sockaddr_in  CIPv4SocketAddress;
typedef struct in_addr      CIPv4Address;
typedef in_addr_t           CIPv4AddressBase;
typedef struct sockaddr_in6 CIPv6SocketAddress;
typedef struct in6_addr     CIPv6Address;
typedef struct sockaddr_un  CUNIXSocketAddress;

typedef struct addrinfo CSocketAddressInformation;


// MARK: - Shim Values/Types

/// `INET_ADDRSTRLEN`
static const size_t cNWGIPv4AddressStringLength = INET_ADDRSTRLEN;

/// `INET6_ADDRSTRLEN`
static const size_t cNWGIPv6AddressStringLength = INET6_ADDRSTRLEN;

static const size_t cNWGUNIXSocketAddressPathLength = sizeof(((CUNIXSocketAddress *)0)->sun_path);

/// `NI_MAXHOST`
static const size_t cNWGNameInfoMaxHostnameLength = NI_MAXHOST;

/// `NI_MAXSERV`
static const size_t cNWGNameInfoMaxServericeNameLength = NI_MAXSERV;

/// `IPPROTO_*`
typedef enum _CNWGIPProtocol {
  /// `IPPROTO_IP`
  cNWGInternetProtocol = IPPROTO_IP,
  /// `IPPROTO_ICMP`
  cNWGControlMessageProtocol = IPPROTO_ICMP,
  /// `IPPROTO_TCP`
  cNWGTransmissionControlProtocol = IPPROTO_TCP,
#ifdef IPPROTO_IPV4
  /// `IPPROTO_IPV4`
  cNWGIPv4EncapsulationProtocol = IPPROTO_IPV4,
#elif defined(IPPROTO_IPIP)
  /// `IPPROTO_IPIP`
  cNWGIPv4EncapsulationProtocol = IPPROTO_IPIP,
#endif
  /// `IPPROTO_UDP`
  cNWGUserDatagramProtocol = IPPROTO_UDP,
  /// `IPPROTO_IPV6`
  cNWGIPv6HeaderProtocol = IPPROTO_IPV6,
  /// `IPPROTO_RAW`
  cNWGRawIPPacketProtocol = IPPROTO_RAW,
} CNWGIPProtocol;

typedef enum {
  // MARK: - Darwin & Linux
  cNWGUnspecifiedAddressFamily = AF_UNSPEC,
  cNWGUNIXAddressFamily = AF_UNIX,
  cNWGIPv4AddressFamily = AF_INET,
  cNWGIPv6AddressFamily = AF_INET6,
  cNWGVMSocketAddressFamily = AF_VSOCK,

#if defined(AF_LOCAL)
  cNWGLocalAddressFamily = AF_LOCAL,
#endif
#if defined(AF_DECnet)
  cNWGDECnetAddressFamily = AF_DECnet,
#endif
#if defined(AF_ROUTE)
  cNWGInternalRoutingProtocolAddressFamily = AF_ROUTE,
#endif
#if defined(AF_SNA)
  cNWGSNAAddressFamily = AF_SNA,
#endif
#if defined(AF_ISDN)
  cNWGISDNAddressFamily = AF_ISDN,
#endif

  cNWGAddressFamilyMaxValue = AF_MAX,

  // MARK: - Darwin
#if defined(AF_IMPLINK)
  cNWGArpanetIMPAddressFamily = AF_IMPLINK,
#endif
#if defined(AF_PUP)
  cNWGPARCUniversalPacketAddressFamily = AF_PUP,
#endif
#if defined(AF_CHAOS)
  cNWGChaosProtocolAddressFamily = AF_CHAOS,
#endif
#if defined(AF_NS)
  cNWGXEROXNSProtocolAddressFamily = AF_NS,
#endif
#if defined(AF_ISO)
  cNWGISOProtocolAddressFamily = AF_ISO,
#endif
#if defined(AF_OSI)
  cNWGOSIProtocolAddressFamily = AF_OSI,
#endif
#if defined(AF_ECMA)
  cNWGECMAAddressFamily = AF_ECMA,
#endif
#if defined(AF_DATAKIT)
  cNWGDatakitProtocolAddressFamily = AF_DATAKIT,
#endif
#if defined(AF_CCITT)
  cNWGCCITTProtocolAddressFamily = AF_CCITT,
#endif
#if defined(AF_DLI)
  cNWGDECDirectDataLinkInterfaceAddressFamily = AF_DLI,
#endif
#if defined(AF_LAT)
  cNWGLATProtocolAddressFamily = AF_LAT,
#endif
#if defined(AF_HYLINK)
  cNWGHyperchannelAddressFamily = AF_HYLINK,
#endif
#if defined(AF_APPLETALK)
  cNWGAppleTalkAddressFamily = AF_APPLETALK,
#endif
#if defined(AF_LINK)
  cNWGLinkLayerInterfaceAddressFamily = AF_LINK,
#endif
#if defined(AF_COIP)
  cNWGConnectionOrientedIPAddressFamily = AF_COIP,
#endif
#if defined(AF_CNT)
  cNWGComputerNetworkTechnologyAddressFamily = AF_CNT,
#endif
#if defined(AF_IPX)
  cNWGNovellInternetProtocolAddressFamily = AF_IPX,
#endif
#if defined(AF_SIP)
  cNWGSimpleInternetProtocolAddressFamily = AF_SIP,
#endif
#if defined(AF_NDRV)
  cNWGNetworkDriverRawAccessAddressFamily = AF_NDRV,
#endif
#if defined(AF_NATM)
  cNWGNativeATMAccessAddressFamily = AF_NATM,
#endif
#if defined(AF_SYSTEM)
  cNWGKernelEventMessageAddressFamily = AF_SYSTEM,
#endif
#if defined(AF_NETBIOS)
  cNWGNetBIOSAddressFamily = AF_NETBIOS,
#endif
#if defined(AF_PPP)
  cNWGPPPAddressFamily = AF_PPP,
#endif

  // MARK: - Linux
#if defined(AF_AX25)
  cNWGAX25AddressFamily = AF_AX25,
#endif
#if defined(AF_NETROM)
  cNWGNetROMAddressFamily = AF_NETROM,
#endif
#if defined(AF_BRIDGE)
  cNWGMultiprotocolBridgeAddressFamily = AF_BRIDGE,
#endif
#if defined(AF_ATMPVC)
  cNWGATMPermanentVirtualCircuitAddressFamily = AF_ATMPVC,
#endif
#if defined(AF_X25)
  cNWGX25AddressFamily = AF_X25,
#endif
#if defined(AF_ROSE)
  cNWGRoseAddressFamily = AF_ROSE,
#endif
#if defined(AF_KEY)
  cNWGPFKeySocketAddressFamily = AF_KEY,
#endif
#if defined(AF_NETLINK)
  cNWGNetlinkAddressFamily = AF_NETLINK,
#endif
#if defined(AF_PACKET)
  cNWGPacketAddressFamily = AF_PACKET,
#endif
#if defined(AF_ASH)
  cNWGAshAddressFamily = AF_ASH,
#endif
#if defined(AF_ECONET)
  cNWGEconetAddressFamily = AF_ECONET,
#endif
#if defined(AF_ATMSVC)
  cNWGATMSwitchedVirtualCircuitAddressFamily = AF_ATMSVC,
#endif
#if defined(AF_RDS)
  cNWGRDSSocketAddressFamily = AF_RDS,
#endif
#if defined(AF_IRDA)
  cNWGIRDASocketAddressFamily = AF_IRDA,
#endif
#if defined(AF_PPPOX)
  cNWGPPPoXAddressFamily = AF_PPPOX,
#endif
#if defined(AF_WANPIPE)
  cNWGWanpipeSocketAddressFamily = AF_WANPIPE,
#endif
#if defined(AF_LLC)
  cNWGLogicalLinkControlAddressFamily = AF_LLC,
#endif
#if defined(AF_IB)
  cNWGInfiniBandAddressFamily = AF_IB,
#endif
#if defined(AF_MPLS)
  cNWGMPLSAddressFamily = AF_MPLS,
#endif
#if defined(AF_CAN)
  cNWGControllerAreaNetworkAddressFamily = AF_CAN,
#endif
#if defined(AF_TIPC)
  cNWGTIPCSocketAddressFamily = AF_TIPC,
#endif
#if defined(AF_BLUETOOTH)
  cNWGBluetoothSocketAddressFamily = AF_BLUETOOTH,
#endif
#if defined(AF_IUCV)
  cNWGIUCVSocketAddressFamily = AF_IUCV,
#endif
#if defined(AF_RXRPC)
  cNWGRxRPCSocketAddressFamily = AF_RXRPC,
#endif
#if defined(AF_PHONET)
  cNWGPhonetSocketAddressFamily = AF_PHONET,
#endif
#if defined(AF_IEEE802154)
  cNWGIEEE802154AddressFamily = AF_IEEE802154,
#endif
#if defined(AF_CAIF)
  cNWGCAIFSocketAddressFamily = AF_CAIF,
#endif
#if defined(AF_ALG)
  cNWGAlgorithmSocketAddressFamily = AF_ALG,
#endif
#if defined(AF_NFC)
  cNWGNFCSocketAddressFamily = AF_NFC,
#endif
#if defined(AF_KCM)
  cNWGKernelConnectionMultiplexorAddressFamily = AF_KCM,
#endif
#if defined(AF_QIPCRTR)
  cNWGQualcommIPCRouterAddressFamily = AF_QIPCRTR,
#endif
#if defined(AF_SMC)
  cNWGSMCSocketAddressFamily = AF_SMC,
#endif
#if defined(AF_XDP)
  cNWGXDPSocketAddressFamily = AF_XDP,
#endif
#if defined(AF_MCTP)
  cNWGManagementComponentTransportProtocolAddressFamily = AF_MCTP,
#endif
} CNWGSocketAddressFamily;

/// `AI_*`
typedef enum _CNWGSocketAddressInformationFlag {
  cNWGAIFlagPassive = AI_PASSIVE,
  cNWGAIFlagCanonicalNameRequest = AI_CANONNAME,
  cNWGAIFlagDisallowHostnameResolution = AI_NUMERICHOST,
  cNWGAIFLagAcceptIPv4MappedAddress = AI_V4MAPPED,
  cNWGAIFlagIncludeBothIPv4MappedAndIPv6Address = AI_ALL,
  cNWGAIFlagUseHostConfiguration = AI_ADDRCONFIG,
  cNWGAIFlagDisallowServiceNameResolution = AI_NUMERICSERV,
} CNWGSocketAddressInformationFlag;

typedef enum {
  cNWGStreamSocket = SOCK_STREAM,
  cNWGDatagramSocket = SOCK_DGRAM,
  cNWGRawProtocolSocket = SOCK_RAW,
  cNWGReliablyDeliveredMessageSocket = SOCK_RDM,
  cNWGSequencedPacketStreamSocket = SOCK_SEQPACKET,
} CNWGSocketType;


// MARK: - Shim Functions

/// Call `inet_ntop`.
const char * _Nullable CNWGIPAddressToString(CNWGSocketAddressFamily family,
                                             const void * _Nonnull restrict source,
                                             char * _Nonnull restrict destination,
                                             CSocketRelatedSize size);

/// Call `inet_pton`.
int CNWGStringToIPAddress(CNWGSocketAddressFamily family,
                          const char * _Nonnull restrict source,
                          void * _Nonnull restrict destination);

void CNWGIPv6AddressGetBytes(CIPv6Address const * _Nonnull address,
                             uint8_t * _Nonnull buffer);

void CNWGIPv6AddressSetBytes(CIPv6Address * _Nonnull address,
                             uint8_t const * _Nonnull source);

static inline CSocketAddressSize CNWGSocketAddressSizeOf(const CSocketAddress * _Nonnull addr) {
#ifdef __linux__
  return (CSocketAddressSize)sizeof(CSocketAddress);
#else
  return addr->sa_len;
#endif
}

static inline CSocketAddressSize CNWGIPv4SocketAddressSizeOf(const CIPv4SocketAddress *  _Nonnull addr) {
#ifdef __linux__
  return (CSocketAddressSize)sizeof(CIPv4SocketAddress);
#else
  return addr->sin_len;
#endif
}

static inline CSocketAddressSize CNWGIPv6SocketAddressSizeOf(const CIPv6SocketAddress * _Nonnull addr) {
#ifdef __linux__
  return (CSocketAddressSize)sizeof(CIPv6SocketAddress);
#else
  return addr->sin6_len;
#endif
}

static inline CSocketAddressSize CNWGUNIXSocketAddressSizeOf(const CUNIXSocketAddress * _Nonnull addr) {
#ifdef __linux__
  return (CSocketAddressSize)sizeof(CUNIXSocketAddress);
#else
  return addr->sun_len;
#endif
}

void CNWGUNIXSocketAddressGetPath(const CUNIXSocketAddress * _Nonnull address,
                                  char * _Nonnull buffer);

/// Returns `true` if successful.
///
/// `path` must be null-terminated.
bool CNWGUNIXSocketAddressSetPath(CUNIXSocketAddress * _Nonnull address,
                                  const char * _Nonnull path);


#endif
