/***************************************************************************************************
 sockaddr-tests.c
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

#include "sockaddr-tests.h"

void _sat_free(struct sockaddr * pointer) {
  free(pointer);
}

struct sockaddr * _sat_un() {
  struct sockaddr_un * pointer = (struct sockaddr_un *)calloc(1, sizeof(struct sockaddr_un));
#ifndef __linux
  pointer->sun_len = sizeof(struct sockaddr_un);
#endif
  pointer->sun_family = AF_UNIX;
  strncpy(pointer->sun_path, "test", 5);
  return (struct sockaddr *)pointer;
}

struct sockaddr * _sat_in() {
  struct sockaddr_in * pointer = (struct sockaddr_in *)calloc(1, sizeof(struct sockaddr_in));
#ifndef __linux
  pointer->sin_len = sizeof(struct sockaddr_in);
#endif
  pointer->sin_family = AF_INET;
  pointer->sin_port = htons(12345);
  pointer->sin_addr.s_addr = htonl(0x7F000001);
  return (struct sockaddr *)pointer;
}

struct sockaddr * _sat_in6() {
  struct sockaddr_in6 * pointer = (struct sockaddr_in6 *)calloc(1, sizeof(struct sockaddr_in6));
#ifndef __linux
  pointer->sin6_len = sizeof(struct sockaddr_in6);
#endif
  pointer->sin6_family = AF_INET6;
  pointer->sin6_port = htons(12345);
  pointer->sin6_flowinfo = 0;
  pointer->sin6_scope_id = 0;
  
  uint8_t addr[16] = {0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF,0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF};
  for (uint_fast8_t ii = 0;ii < 16;ii++) {
    pointer->sin6_addr.s6_addr[ii] = addr[ii];
  }
  
  return (struct sockaddr *)pointer;
}
