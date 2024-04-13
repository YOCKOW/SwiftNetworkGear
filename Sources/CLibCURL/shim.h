/* *************************************************************************************************
 CLibCURL/shim.h
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#ifndef yCLibCURL
#define yCLibCURL
#include <stddef.h>
#include <stdint.h>
#include <curl/curl.h>

// Note: `curl_easy_nextheader` is supported in curl >=7.84.0.
//       But `apt` on Ubuntu 22.0 installs curl 7.81.0. 😭 (2nd Apr. 2024)

// Swifty Names
typedef size_t CSize;
typedef curl_off_t CCURLOffset;
typedef long CURLResponseCode;
typedef struct curl_slist CCURLStringList;

static CURLcode _NWG_curl_easy_get_response_code(CURL * _Nonnull curl,
                                                 CURLResponseCode * _Nonnull codePointer) {
  return curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, codePointer);
}

static CURLcode _NWG_curl_easy_perform(CURL * _Nonnull curl) {
  return curl_easy_perform(curl);
}

typedef size_t (* _NWGCURLHeaderCallbackFunction)(char * _Nonnull buffer,
                                                  size_t size,
                                                  size_t nitems,
                                                  void * _Nullable userdata);
static CURLcode _NWG_curl_easy_set_header_callback(CURL * _Nonnull curl,
                                                   _NWGCURLHeaderCallbackFunction _Nullable callback) {
  return curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, callback);
}

static CURLcode _NWG_curl_easy_set_header_user_info(CURL * _Nonnull curl, void * _Nullable userInfo) {
  return curl_easy_setopt(curl, CURLOPT_HEADERDATA, userInfo);
}

static CURLcode _NWG_curl_easy_set_http_method_to_get(CURL * _Nonnull curl) {
  return curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
}

static CURLcode _NWG_curl_easy_set_http_method_to_post(CURL * _Nonnull curl) {
  return curl_easy_setopt(curl, CURLOPT_POST, 1L);
}

static CURLcode _NWG_curl_easy_set_http_method_to_put(CURL * _Nonnull curl) {
  return curl_easy_setopt(curl, CURLOPT_UPLOAD, 1L);
}

static CURLcode _NWG_curl_easy_set_http_request_headers(CURL * _Nonnull curl,
                                                        CCURLStringList * _Nullable headers) {
  return curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
}

static CURLcode _NWG_curl_easy_set_read_user_info(CURL * _Nonnull curl, void * _Nullable userInfo) {
  return curl_easy_setopt(curl, CURLOPT_READDATA, userInfo);
}

typedef size_t (* _NWGCURLReadCallbackFunction)(char * _Nonnull buffer,
                                                size_t size,
                                                size_t nitems,
                                                void * _Nullable userdata);
static CURLcode _NWG_curl_easy_set_read_function(CURL * _Nonnull curl,
                                                 _NWGCURLReadCallbackFunction _Nullable callback) {
  return curl_easy_setopt(curl, CURLOPT_READFUNCTION, callback);
}

static CURLcode _NWG_curl_easy_set_ua(CURL * _Nonnull curl, const char * _Nonnull ua) {
  return curl_easy_setopt(curl, CURLOPT_USERAGENT, ua);
}

static CURLcode _NWG_curl_easy_set_upload_file_size(CURL * _Nonnull curl, CCURLOffset filesize) {
  if (filesize <= ((CCURLOffset)INT32_MAX)) {
    return curl_easy_setopt(curl, CURLOPT_INFILESIZE, (long)filesize);
  } else {
    return curl_easy_setopt(curl, CURLOPT_INFILESIZE_LARGE, filesize);
  }
}

static CURLcode _NWG_curl_easy_set_url(CURL * _Nonnull curl, const char * _Nonnull url) {
  return curl_easy_setopt(curl, CURLOPT_URL, url);
}

static CURLcode _NWG_curl_easy_set_write_user_info(CURL * _Nonnull curl, void * _Nullable pointer) {
  return curl_easy_setopt(curl, CURLOPT_WRITEDATA,  pointer);
}

typedef size_t (* _NWGCURLWriteCallbackFunction)(char * _Nonnull, size_t, size_t, void * _Nullable);
static CURLcode _NWG_curl_easy_set_write_function(CURL * _Nonnull curl,
                                                  _NWGCURLWriteCallbackFunction _Nullable callback) {
  return curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, callback);
}

static CCURLStringList * _Nullable _NWG_curl_slist_create(const char * _Nonnull string) {
  return curl_slist_append(NULL, string);
}

static CCURLStringList * _Nullable _NWG_curl_slist_append(CCURLStringList * _Nonnull list,
                                                          const char * _Nonnull newString) {
  return curl_slist_append(list, newString);
}

void _NWG_curl_slist_free_all(CCURLStringList * _Nullable list) {
  curl_slist_free_all(list);
}

#endif
