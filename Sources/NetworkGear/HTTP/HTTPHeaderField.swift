/* *************************************************************************************************
 HeaderField.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 

/// # HeaderField
/// Represents each HTTP Header Field.
public struct HTTPHeaderField {
  /// Represents how it can be in the header.
  public enum PresenceType {
    /// There are no other fields of the same name in the same header.
    /// e.g.) "ETag"
    case single
    
    /// There may be other fields of the same name in the same header.
    /// e.g.) "Set-Cookie"
    case duplicable
    
    /// The value of the field can be appended.
    /// e.g.) "Cache-Control"
    case appendable
  }
  
  // testable
  internal var _delegate: _AnyHTTPHeaderFieldDelegate

  public var name:HTTPHeaderFieldName {
    return self._delegate.name
  }

  public var value:HTTPHeaderFieldValue {
    return self._delegate.value
  }
  
  /// Returns the source of HTTP header value.
  public var source: Any {
    return self._delegate.source
  }

  /// Returns the Boolean value that indicates whether the field is duplicable or not.
  /// e.g.) "Set-Cookie" field is duplicable.
  public var isDuplicable:Bool {
    return self._delegate.type == .duplicable
  }

  /// Returns the Boolean value that indicates whether the field is appendable or not.
  /// e.g.) "Cache-Control" field is appendable.
  public var isAppendable:Bool {
    return self._delegate.type == .appendable
  }
  
  internal init(_ delegate:_AnyHTTPHeaderFieldDelegate) {
    self._delegate = delegate
  }

  /// Creates an instance with `delegate`
  public init<D>(delegate:D) where D: HTTPHeaderFieldDelegate {
    self.init(_AnyHTTPHeaderFieldDelegate(delegate))
  }
  
  /// Creates an instance with `delegate`
  public init<D>(delegate:D) where D: AppendableHTTPHeaderFieldDelegate {
    self.init(_AnyHTTPHeaderFieldDelegate(delegate))
  }
}
