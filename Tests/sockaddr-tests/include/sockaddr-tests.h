/***************************************************************************************************
 sockaddr-tests.h
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

// For the purpose of testing `SocketAddress`

#include <stdlib.h>
#include <string.h>

#include <sys/socket.h>
#include <sys/un.h>

#include <netinet/in.h>


void _sat_free(struct sockaddr * pointer);
struct sockaddr * _sat_un(void);
struct sockaddr * _sat_in(void);
struct sockaddr * _sat_in6(void);

