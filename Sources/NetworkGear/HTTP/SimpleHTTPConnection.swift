/* *************************************************************************************************
 SimpleHTTPConnection.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CURLClient
import Foundation

/// A simple connection using HTTP where its backend is libcurl.
public actor SimpleHTTPConnection {
  public enum Error: Swift.Error {
    case alreadyRequested
  }

  /// A representation of HTTP request.
  public struct Request {
    /// An abstract representation of HTTP request body.
    public struct Body {
      fileprivate let _body: CURLClientGeneralDelegate.RequestBody

      public init(_ body: CURLClientGeneralDelegate.RequestBody) {
        self._body = body
      }

      public init<T>(_ sender: T) where T: CURLRequestBodySender {
        self._body = .init(sender)
      }

      /// Initializes a request body with given `stream`.
      ///
      /// - Note: The given `stream` must not be read from other than the connection intended.
      public init(stream: InputStream) {
        self._body = .init(stream: stream)
      }

      public init(data: Data) {
        self._body = .init(data: data)
      }

      public init<D>(data: D) where  D: DataProtocol {
        self._body = .init(data: data)
      }

      public init<A>(_ sequence: A) where A: AsyncSequence, A.Element == UInt8 {
        self._body = .init(sequence)
      }

      public init<S>(_ sequence: S) where S: Sequence, S.Element == UInt8 {
        self._body = .init(sequence)
      }
    }

    /// The URL to send the request to.
    public let url: URL

    /// HTTP method to be used.
    public let method: HTTPMethod

    /// HTTP header fields to be use for the request.
    ///
    /// Some fields (i.g. `User-Agent`) are set automatically to default values.
    public let header: HTTPHeader?

    /// Request body.
    public let body: Body?

    /// Initializes the instance with given parameters.
    public init(url: URL, method: HTTPMethod = .get, header: HTTPHeader? = nil, body: Body? = nil) {
      self.url = url
      self.method = method
      self.header = header
      self.body = body
    }
  }

  public let request: Request

  /// Creates a connection with given request.
  public init(request: Request) {
    self.request = request
  }

  /// Creates a connection with given parameters.
  public init(url: URL, method: HTTPMethod = .get, header: HTTPHeader? = nil, body: Request.Body? = nil) {
    self.init(request: .init(url: url, method: method, header: header, body: body))
  }

  // MARK: - Fetch the response

  /// A representation of HTTP response body.
  public struct Response<Body> {
    private let _delegate: CURLClientGeneralDelegate

    fileprivate init(_ delegate: CURLClientGeneralDelegate) {
      self._delegate = delegate
    }

    public var statusCode: HTTPStatusCode {
      return HTTPStatusCode(rawValue: UInt16(_delegate.responseCode))!
    }

    public var header: HTTPHeader {
      return _delegate.responseHeaderFields.reduce(into: []) {
        if let name = HTTPHeaderFieldName(rawValue: $1.name),
           let value = HTTPHeaderFieldValue(rawValue: $1.value) {
          $0.insert(HTTPHeaderField(name: name, value: value))
        }
      }
    }

    public var content: Body? {
      return _delegate.responseBody(as: Body.self)
    }
  }

  private func _makeClientAndDelegate(
    responseBody: CURLClientGeneralDelegate.ResponseBody
  ) async throws -> (EasyClient, CURLClientGeneralDelegate) {
    let client = try CURLManager.shared.makeEasyClient()
    try await client.setURL(request.url)

    switch request.method {
    case .get:
      try await client.setHTTPMethodToGet()
    case .head:
      try await client.setHTTPMethodToHead()
    case .post:
      try await client.setHTTPMethodToPost()
    case .put:
      try await client.setHTTPMethodToPut()
    default:
      try await client.setHTTPMethodToCustom(request.method.rawValue)
    }
    let requestHeaderFields: [CURLHeaderField]? = request.header?.reduce(into: [], {
      $0.append((name: $1.name.rawValue, value: $1.value.rawValue))
    })
    let delegate = CURLClientGeneralDelegate(
      requestHeaderFields: requestHeaderFields,
      requestBody: request.body?._body,
      responseBody: responseBody
    )

    return (client, delegate)
  }

  private var _requested: Bool = false

  private func _response<T>(
    responseBody: CURLClientGeneralDelegate.ResponseBody
  ) async throws -> Response<T> {
    if _requested {
      throw Error.alreadyRequested
    }
    _requested = true

    let clientAndDelegate = try await _makeClientAndDelegate(responseBody: responseBody)
    let client = clientAndDelegate.0
    var delegate = clientAndDelegate.1
    try await client.perform(delegate: &delegate)
    return Response<T>(delegate)
  }

  /// Perform the HTTP request and fetch the response.
  public func response() async throws -> Response<Data> {
    let responseBody = CURLClientGeneralDelegate.ResponseBody(data: Data())
    return try await _response(responseBody: responseBody)
  }
}
