//# DO NOT MODIFY.
//# This is autogenerated by `ySwiftCodeUpdater`(https://github.com/YOCKOW/ySwiftCodeUpdater).
//# Please see documents in this project to learn how to regenerate.
//# The material(s) to generate this file was/were obtained from below:
//
// URL: https://www.iana.org/assignments/http-status-codes/http-status-codes-1.csv
// Last-Modified: 2024-08-23T19:00:28Z

public enum HTTPStatusCode: UInt16, Sendable {
  case `continue` = 100
  case switchingProtocols = 101
  case processing = 102
  case earlyHints = 103
  case ok = 200
  case created = 201
  case accepted = 202
  case nonAuthoritativeInformation = 203
  case noContent = 204
  case resetContent = 205
  case partialContent = 206
  case multiStatus = 207
  case alreadyReported = 208
  case imUsed = 226
  case multipleChoices = 300
  case movedPermanently = 301
  case found = 302
  case seeOther = 303
  case notModified = 304
  case useProxy = 305
  case temporaryRedirect = 307
  case permanentRedirect = 308
  case badRequest = 400
  case unauthorized = 401
  case paymentRequired = 402
  case forbidden = 403
  case notFound = 404
  case methodNotAllowed = 405
  case notAcceptable = 406
  case proxyAuthenticationRequired = 407
  case requestTimeout = 408
  case conflict = 409
  case gone = 410
  case lengthRequired = 411
  case preconditionFailed = 412
  case contentTooLarge = 413
  case uriTooLong = 414
  case unsupportedMediaType = 415
  case rangeNotSatisfiable = 416
  case expectationFailed = 417
  case misdirectedRequest = 421
  case unprocessableContent = 422
  case locked = 423
  case failedDependency = 424
  case tooEarly = 425
  case upgradeRequired = 426
  case preconditionRequired = 428
  case tooManyRequests = 429
  case requestHeaderFieldsTooLarge = 431
  case unavailableForLegalReasons = 451
  case internalServerError = 500
  case notImplemented = 501
  case badGateway = 502
  case serviceUnavailable = 503
  case gatewayTimeout = 504
  case httpVersionNotSupported = 505
  case variantAlsoNegotiates = 506
  case insufficientStorage = 507
  case loopDetected = 508
  case notExtendedOBSOLETED = 510
  case networkAuthenticationRequired = 511
}
extension HTTPStatusCode {
  public var reasonPhrase: String {
    switch self {
    case .continue: return "Continue"
    case .switchingProtocols: return "Switching Protocols"
    case .processing: return "Processing"
    case .earlyHints: return "Early Hints"
    case .ok: return "OK"
    case .created: return "Created"
    case .accepted: return "Accepted"
    case .nonAuthoritativeInformation: return "Non-Authoritative Information"
    case .noContent: return "No Content"
    case .resetContent: return "Reset Content"
    case .partialContent: return "Partial Content"
    case .multiStatus: return "Multi-Status"
    case .alreadyReported: return "Already Reported"
    case .imUsed: return "IM Used"
    case .multipleChoices: return "Multiple Choices"
    case .movedPermanently: return "Moved Permanently"
    case .found: return "Found"
    case .seeOther: return "See Other"
    case .notModified: return "Not Modified"
    case .useProxy: return "Use Proxy"
    case .temporaryRedirect: return "Temporary Redirect"
    case .permanentRedirect: return "Permanent Redirect"
    case .badRequest: return "Bad Request"
    case .unauthorized: return "Unauthorized"
    case .paymentRequired: return "Payment Required"
    case .forbidden: return "Forbidden"
    case .notFound: return "Not Found"
    case .methodNotAllowed: return "Method Not Allowed"
    case .notAcceptable: return "Not Acceptable"
    case .proxyAuthenticationRequired: return "Proxy Authentication Required"
    case .requestTimeout: return "Request Timeout"
    case .conflict: return "Conflict"
    case .gone: return "Gone"
    case .lengthRequired: return "Length Required"
    case .preconditionFailed: return "Precondition Failed"
    case .contentTooLarge: return "Content Too Large"
    case .uriTooLong: return "URI Too Long"
    case .unsupportedMediaType: return "Unsupported Media Type"
    case .rangeNotSatisfiable: return "Range Not Satisfiable"
    case .expectationFailed: return "Expectation Failed"
    case .misdirectedRequest: return "Misdirected Request"
    case .unprocessableContent: return "Unprocessable Content"
    case .locked: return "Locked"
    case .failedDependency: return "Failed Dependency"
    case .tooEarly: return "Too Early"
    case .upgradeRequired: return "Upgrade Required"
    case .preconditionRequired: return "Precondition Required"
    case .tooManyRequests: return "Too Many Requests"
    case .requestHeaderFieldsTooLarge: return "Request Header Fields Too Large"
    case .unavailableForLegalReasons: return "Unavailable For Legal Reasons"
    case .internalServerError: return "Internal Server Error"
    case .notImplemented: return "Not Implemented"
    case .badGateway: return "Bad Gateway"
    case .serviceUnavailable: return "Service Unavailable"
    case .gatewayTimeout: return "Gateway Timeout"
    case .httpVersionNotSupported: return "HTTP Version Not Supported"
    case .variantAlsoNegotiates: return "Variant Also Negotiates"
    case .insufficientStorage: return "Insufficient Storage"
    case .loopDetected: return "Loop Detected"
    case .notExtendedOBSOLETED: return "Not Extended (OBSOLETED)"
    case .networkAuthenticationRequired: return "Network Authentication Required"
    }
  }
}
