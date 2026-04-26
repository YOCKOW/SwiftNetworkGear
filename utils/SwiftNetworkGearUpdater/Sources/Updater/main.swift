/* *************************************************************************************************
 main.swift
  © 2020,2026 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import NetworkGearUpdater
import yCodeUpdater

let manager = CodeUpdaterManager(updaters: [
  .init(delegate: ContentDispositionValue()),
  .init(delegate: HTTPMethod()),
  .init(delegate: HTTPStatusCode()),
  .init(delegate: IANARegisteredContentDispositionParameterKey()),
  .init(delegate: IANARegisteredHTTPHeaderFieldName()),
  .init(delegate: MIMETypePathExtension()),
])

await manager.run()
