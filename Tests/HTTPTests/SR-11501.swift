/* *************************************************************************************************
 SR-11501.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest

// Workaround for https://bugs.swift.org/browse/SR-11501
#if SWIFT_PACKAGE // && compiler(<5.x)
private struct XCTestErrorWhileUnwrappingOptional: Error, CustomNSError {
  static let errorDomain: String = XCTestErrorDomain
  var errorCode: Int = 105
  var errorUserInfo: [String: Any] { return ["XCTestErrorUserInfoKeyShouldIgnore": true] }
}
internal func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?,
                         _ message: @autoclosure () -> String = "",
                         file: StaticString = #file, line: UInt = #line) throws -> T
{
  // Maybe different behaviour from Apple's implementation
  guard let result = try expression() else { throw XCTestErrorWhileUnwrappingOptional() }
  return result
}
#endif
