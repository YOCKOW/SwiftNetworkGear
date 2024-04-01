/* *************************************************************************************************
 CLibCURL/shim.h
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#ifndef yCLibCURL
#define yCLibCURL
#include <curl/curl.h>

static CURLcode _NWG_curl_easy_perform(CURL * _Nonnull curl) {
  return curl_easy_perform(curl);
}

static CURLcode _NWG_curl_easy_set_http_method_to_get(CURL * _Nonnull curl) {
  return curl_easy_setopt(curl, CURLOPT_HTTPGET, 1);
}

static CURLcode _NWG_curl_easy_set_ua(CURL * _Nonnull curl, const char * _Nonnull ua) {
  return curl_easy_setopt(curl, CURLOPT_USERAGENT, ua);
}

static CURLcode _NWG_curl_easy_set_url(CURL * _Nonnull curl, const char * _Nonnull url) {
  return curl_easy_setopt(curl, CURLOPT_URL, url);
}

#endif
