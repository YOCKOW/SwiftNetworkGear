/* *************************************************************************************************
 CNetworkGear.c
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#include <string.h>
#include "CNetworkGear.h"

const char * _Nullable CNWGIPAddressToString(CNWGSocketAddressFamily family,
                                             const void * _Nonnull restrict source,
                                             char * _Nonnull restrict destination,
                                             CSocketRelatedSize size) {
  return inet_ntop((int)family, source, destination, size);
}

/// Call `inet_pton`.
int CNWGStringToIPAddress(CNWGSocketAddressFamily family,
                          const char * _Nonnull restrict source,
                          void * _Nonnull restrict destination) {
  return inet_pton((int)family, source, destination);
}

void CNWGIPv6AddressGetBytes(CIPv6Address const * _Nonnull address,
                             uint8_t * _Nonnull buffer) {
#if defined(s6_addr32)
  uint32_t * uint32ArrayBuffer = (uint32_t *)buffer;
  for (int ii = 0; ii < 4; ii++) {
    uint32ArrayBuffer[ii] = address->s6_addr32[ii];
  }
#else
  for (int ii = 0; ii < 16; ii++) {
    buffer[ii] = address->s6_addr[ii];
  }
#endif
}

void CNWGIPv6AddressSetBytes(CIPv6Address * _Nonnull address,
                             uint8_t const * _Nonnull source) {
#if defined(s6_addr32)
  uint32_t * uint32ArraySource = (uint32_t *)source;
  for (int ii = 0; ii < 4; ii++) {
    address->s6_addr32[ii] = uint32ArraySource[ii];
  }
#else
  for (int ii = 0; ii < 16; ii++) {
    address->s6_addr[ii] = source[ii];
  }
#endif
}

void CNWGUNIXSocketAddressGetPath(const CUNIXSocketAddress * _Nonnull address,
                                  char * _Nonnull buffer) {
  strcpy(buffer, address->sun_path);
}

bool CNWGUNIXSocketAddressSetPath(CUNIXSocketAddress * _Nonnull address,
                                  const char * _Nonnull path) {
  size_t underestimatedLength = 0;
  while (true) {
    const char currentChar = path[underestimatedLength];
    underestimatedLength++;
    if (currentChar == 0) {
      break;
    }
    if (underestimatedLength > cNWGUNIXSocketAddressPathLength) {
      return false;
    }
  }
  
  memset(address->sun_path, 0, cNWGUNIXSocketAddressPathLength);
  strcpy(address->sun_path, path);
  return true;
}
