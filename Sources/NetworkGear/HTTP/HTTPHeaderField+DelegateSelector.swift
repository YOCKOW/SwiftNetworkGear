/* *************************************************************************************************
 HTTPHeaderField+DelegateSelector.swift
   © 2018,2020,2023-2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import yExtensions

extension HTTPHeaderField {
  /// Metatype-erasure for `HeaderFieldDelegate`
  private class _TypeBox: @unchecked Sendable {
    fileprivate func headerField(with value: HTTPHeaderFieldValue,
                                 userInfo: [AnyHashable: Any]?) -> HTTPHeaderField?
    {
      fatalError("Must be overridden.")
    }
    
    fileprivate class _Normal<Delegate>: _TypeBox, @unchecked Sendable where Delegate:HTTPHeaderFieldDelegate {
      private let _type: Delegate.Type
      fileprivate init(_ type:Delegate.Type) {
        self._type = type
      }
      
      fileprivate override func headerField(with value: HTTPHeaderFieldValue,
                                            userInfo: [AnyHashable: Any]?) -> HTTPHeaderField?
      {
        guard let delegate = Delegate(value) else { return nil }
        return HTTPHeaderField(delegate: delegate)
      }
    }

    fileprivate class _ExtInfo<Delegate>: _Normal<Delegate>, @unchecked Sendable where Delegate: ExternalInformationReferenceableHTTPHeaderFieldDelegate {
      override func headerField(with value: HTTPHeaderFieldValue,
                                userInfo: [AnyHashable: Any]?) -> HTTPHeaderField? {
        guard let delegate = Delegate(value, userInfo: userInfo) else { return nil }
        return HTTPHeaderField(delegate: delegate)
      }
    }
    
    fileprivate class _Appendable<Delegate>: _Normal<Delegate>, @unchecked Sendable
      where Delegate:AppendableHTTPHeaderFieldDelegate
    {
      fileprivate override func headerField(with value: HTTPHeaderFieldValue,
                                            userInfo: [AnyHashable: Any]?) -> HTTPHeaderField?
      {
        guard let delegate = Delegate(value) else { return nil }
        return HTTPHeaderField(delegate: delegate)
      }
    }
  }
  
  public final class DelegateSelector: @unchecked Sendable {
    private init() {}
    public static let `default` = DelegateSelector()
    
    private var _list:[HTTPHeaderFieldName:_TypeBox] = [
      // Here are default delegates implemented in this module.
      .cacheControl: _TypeBox._Appendable(CacheControlHTTPHeaderFieldDelegate.self),
      .contentDisposition: _TypeBox._Normal(ContentDispositionHTTPHeaderFieldDelegate.self),
      .contentLength: _TypeBox._Normal(ContentLengthHTTPHeaderFieldDelegate.self),
      .contentTransferEncoding: _TypeBox._Normal(ContentTransferEncodingHTTPHeaderFieldDelegate.self),
      .contentType: _TypeBox._Normal(MIMETypeHTTPHeaderFieldDelegate.self),
      .eTag: _TypeBox._Normal(HTTPETagHeaderFieldDelegate.self),
      .ifMatch: _TypeBox._Appendable(IfMatchHTTPHeaderFieldDelegate.self),
      .ifNoneMatch: _TypeBox._Appendable(IfNoneMatchHTTPHeaderFieldDelegate.self),
      .lastModified: _TypeBox._Normal(LastModifiedHTTPHeaderFieldDelegate.self),
      .location: _TypeBox._Normal(LocationHTTPHeaderFieldDelegate.self),
      .setCookie: _TypeBox._ExtInfo(SetCookieHTTPHeaderFieldDelegate.self),
    ]
    private let _queue: DispatchQueue = .init(
      label: "jp.YOCKOW.NetworkGear.HTTPHeaderField.DelegateSelector",
      attributes: .concurrent
    )
    private func _withList<T>(_ work: (inout [HTTPHeaderFieldName: _TypeBox]) throws -> T) rethrows -> T {
      return try _queue.sync(flags: .barrier) { try work(&_list) }
    }

    private func _register(_ box:_TypeBox, for name:HTTPHeaderFieldName) -> Bool {
      return _withList {
        if let _ = $0[name] {
          return false
        }
        $0[name] = box
        return true
      }
    }
    
    /// Register the type for the delegate that generates the header field named `name`.
    @discardableResult
    public func register<Delegate>(_ typeObject:Delegate.Type, for name:HTTPHeaderFieldName) -> Bool
      where Delegate: HTTPHeaderFieldDelegate
    {
      return self._register(_TypeBox._Normal(typeObject), for:name)
    }
    
    /// Register the type for the delegate that generates the header field named `name`.
    @discardableResult
    public func register<Delegate>(_ typeObject:Delegate.Type, for name:HTTPHeaderFieldName) -> Bool
      where Delegate: AppendableHTTPHeaderFieldDelegate
    {
      return self._register(_TypeBox._Appendable(typeObject), for:name)
    }
    
    fileprivate func _headerField(name: HTTPHeaderFieldName,
                                  value: HTTPHeaderFieldValue,
                                  userInfo: [AnyHashable: Any]?) -> HTTPHeaderField?
    {
      return _withList {
        guard let box = $0[name] else { return nil }
        return box.headerField(with: value, userInfo: userInfo)
      }
    }
  }
  
  /// Initializes with `name` and `value`.
  /// Appropriate delegate will be selected if the type for the name is registered in
  /// `DelegateSelector.default`.
  public init(name:HTTPHeaderFieldName, value:HTTPHeaderFieldValue, userInfo: [AnyHashable: Any]? = nil) {
    if let field = DelegateSelector.default._headerField(name: name, value: value,
                                                         userInfo: userInfo)
    {
      self = field
    } else {
      self.init(_AnyHTTPHeaderFieldDelegate(name:name, value:value))
    }
  }
  
  public init?(string: String, userInfo: [AnyHashable: Any]? = nil) {
    guard case let (nameString, valueString?) = string.splitOnce(separator:":") else { return nil }
    guard let name = HTTPHeaderFieldName(rawValue: _trim(nameString)),
          let value = HTTPHeaderFieldValue(rawValue: _trim(valueString))
    else {
      return nil
    }
    self.init(name: name, value: value, userInfo: userInfo)
  }
}


