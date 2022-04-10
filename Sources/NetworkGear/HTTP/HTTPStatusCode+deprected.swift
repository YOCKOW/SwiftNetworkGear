/* *************************************************************************************************
 HTTPStatusCode+deprected.swift
   © 2022 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

extension HTTPStatusCode {
  @available(*, deprecated, renamed: "contentTooLarge")
  public static let payloadTooLarge: HTTPStatusCode = .contentTooLarge

  @available(*, deprecated, renamed: "unprocessableContent")
  public static let unprocessableEntity: HTTPStatusCode = .unprocessableContent
}
