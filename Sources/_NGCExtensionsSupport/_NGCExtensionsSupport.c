/* *************************************************************************************************
 _NGCExtensionsSupport.c
   © 2021 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#include "_NGCExtensionsSupport.h"

_NGCESocketRelatedSize _kNGCEIPv4AddressStringLength = INET_ADDRSTRLEN;
_NGCESocketRelatedSize _kNGCEIPv6AddressStringLength = INET6_ADDRSTRLEN;

_NGCESocketAddressFamily _kNGCESocketAddressFamilyIPv4 = AF_INET;
_NGCESocketAddressFamily _kNGCESocketAddressFamilyIPv6 = AF_INET6;
_NGCESocketAddressFamily _kNGCESocketAddressFamilyUNIX = AF_UNIX;
_NGCESocketAddressFamily _kNGCESocketAddressFamilyUnspecified = AF_UNSPEC;

_NGCEAddressInformationFlag _kNGCEAddressInformationFlagPassive = AI_PASSIVE;
_NGCEAddressInformationFlag _kNGCEAddressInformationFlagCanonicalName = AI_CANONNAME;
_NGCEAddressInformationFlag _kNGCEAddressInformationFlagNumericHost = AI_NUMERICHOST;
_NGCEAddressInformationFlag _kNGCEAddressInformationFlagV4Mapped = AI_V4MAPPED;
_NGCEAddressInformationFlag _kNGCEAddressInformationFlagAll = AI_ALL;
_NGCEAddressInformationFlag _kNGCEAddressInformationFlagAddressConfiguration = AI_ADDRCONFIG;
_NGCEAddressInformationFlag _kNGCEAddressInformationFlagNumericService = AI_NUMERICSERV;

_NGCESocketProtocolFamily _kNGCESocketProtocolFamilyTCP = IPPROTO_TCP;
_NGCESocketProtocolFamily _kNGCESocketProtocolFamilyUDP = IPPROTO_UDP;

_NGCESocketType _kNGCESocketTypeStream = SOCK_STREAM;
_NGCESocketType _kNGCESocketTypeDatagram = SOCK_DGRAM;
_NGCESocketType _kNGCESocketTypeRaw = SOCK_RAW;
_NGCESocketType _kNGCESocketTypeReliablyDeliveredMessage = SOCK_RDM;
_NGCESocketType _kNGCESOcketTypeSequencedPacket = SOCK_SEQPACKET;
