/* *************************************************************************************************
 HeaderField+Factory.swift
   © 2018, 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

extension HTTPHeaderField {
  private static func _create<D>(_ delegate:D) -> HTTPHeaderField where D:HTTPHeaderFieldDelegate {
    return HTTPHeaderField(delegate:delegate)
  }
  private static func _create<D>(_ delegate:D) -> HTTPHeaderField where D:AppendableHTTPHeaderFieldDelegate {
    return HTTPHeaderField(delegate:delegate)
  }
  
  public static func cacheControl(_ directives:CacheControlDirectiveSet) -> HTTPHeaderField {
    return ._create(CacheControlHTTPHeaderFieldDelegate(directives))
  }
  
  public static func contentDisposition(_ contentDisposition: ContentDisposition) -> HTTPHeaderField {
    return ._create(ContentDispositionHTTPHeaderFieldDelegate(contentDisposition))
  }
  
  /// Creates the HTTP header field of "Content-Length"
  public static func contentLength(_ length:UInt) -> HTTPHeaderField {
    return ._create(ContentLengthHTTPHeaderFieldDelegate(length))
  }
  
  public static func contentTransferEncoding(_ encoding: ContentTransferEncoding) -> HTTPHeaderField {
    return ._create(ContentTransferEncodingHTTPHeaderFieldDelegate(encoding))
  }
  
  /// Creates the HTTP header field of "Content-Type"
  public static func contentType(_ contentType:MIMEType) -> HTTPHeaderField {
    return ._create(ContentTypeHTTPHeaderFieldDelegate(contentType))
  }
  
  /// Creates the HTTP header field of "ETag"
  public static func eTag(_ eTag:HTTPETag) -> HTTPHeaderField {
    return ._create(HTTPETagHeaderFieldDelegate(eTag))
  }
  
  /// Creates the HTTP header field of "If-Match"
  public static func ifMatch(_ list:HTTPETagList) -> HTTPHeaderField {
    return ._create(IfMatchHTTPHeaderFieldDelegate(list))
  }
  
  /// Creates the HTTP header field of "If-None-Match"
  public static func ifNoneMatch(_ list:HTTPETagList) -> HTTPHeaderField {
    return ._create(IfNoneMatchHTTPHeaderFieldDelegate(list))
  }
  
  public static func lastModified(_ date:Date) -> HTTPHeaderField {
    return ._create(LastModifiedHTTPHeaderFieldDelegate(date))
  }
  
  public static func location(_ url: URL) -> HTTPHeaderField {
    return ._create(LocationHTTPHeaderFieldDelegate(url))
  }
  
  public static func setCookie<C>(_ cookie:C) -> HTTPHeaderField where C:RFC6265Cookie {
    return ._create(SetCookieHTTPHeaderFieldDelegate(cookie:cookie))
  }
}

