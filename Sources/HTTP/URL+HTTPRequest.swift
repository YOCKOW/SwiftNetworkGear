/* *************************************************************************************************
 URL+HTTPRequest.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

private var _headerCache: [URL: Header] = [:]

extension URL {
  /// Represents HTTP Request.
  public struct Request {
    public enum Body {
      case data(Data)
      case stream(InputStream)
    }
    
    public var method: Method
    public var header: Header
    public var body: Body?
    public init(method: Method = .get, header: Header = [], body: Body? = nil) {
      self.method = method
      self.header = header
      self.body = body
    }
  }
  
  /// Represents HTTP Response
  public struct Response {
    public let statusCode: StatusCode
    public let header: Header
    public let content: Data?
    
    fileprivate init(url: URL, response: HTTPURLResponse, data: Data?) {
      self.statusCode = StatusCode(rawValue: UInt16(response.statusCode))!
      
      let userInfo: [AnyHashable: Any] = ["url": url]
      var header: Header = []
      for (maybeName, maybeValue) in response.allHeaderFields {
        if case let nameString as String = maybeName.base,
           case let valueString as String = maybeValue,
           let name = HeaderFieldName(rawValue: nameString),
           let value = HeaderFieldValue(rawValue: valueString)
        {
          header.insert(HeaderField(name: name, value: value, userInfo: userInfo))
        }
      }
      
      self.header = header
      self.content = data
    }
  }
  
  /// Returns an instance of `Response` representing the response to `request`.
  public func response(to request: Request) throws -> Response {
    var urlReq = URLRequest(url: self)
    urlReq.httpMethod = request.method.rawValue
    for field in request.header {
      urlReq.addValue(field.value.rawValue, forHTTPHeaderField: field.name.rawValue)
    }
    switch request.body {
    case .some(.data(let data)):
      urlReq.httpBody = data
    case .some(.stream(let stream)):
      urlReq.httpBodyStream = stream
    default:
      break
    }
    
    enum _Result {
      case error(Error)
      case response(HTTPURLResponse, data: Data?)
    }
    var result: _Result = .error(NSError(domain: "Unexpected Error.", code: -1))
    
    let semaphore = DispatchSemaphore(value: 0)
    let handler: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
      if case let httpResponse as HTTPURLResponse = response {
        result = .response(httpResponse, data: data)
      } else if let someError = error {
        result = .error(someError)
      }
      semaphore.signal()
    }
    let task = URLSession.shared.dataTask(with: urlReq, completionHandler: handler)
    task.resume()
    semaphore.wait()
    
    switch result {
    case .error(let error):
      throw error
    case .response(let httpResponse, data: let data):
      return .init(url: self, response: httpResponse, data: data)
    }
  }
  
  private var _header: Header? {
    if let header = _headerCache[self] {
      return header
    }
    guard let response = try? self.response(to: .init(method: .head)) else { return nil }
    _headerCache[self] = response.header
    return response.header
  }
  
  /// Returns the date when the resource at URL modified last.
  public var lastModified: Date? {
    return self._header?[.lastModified].first?.source as? Date
  }
  
  /// Returns the ETag value of the URL.
  public var eTag: ETag? {
    return self._header?[.eTag].first?.source as? ETag
  }
}
