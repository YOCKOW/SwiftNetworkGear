/* *************************************************************************************************
 NetworkGearUpdater.swift
  © 2020,2024 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

extension URL {
  fileprivate func _deletingLastPathComponent(_ numberOfComponents: Int) -> URL {
    var url = self
    for _ in 0..<numberOfComponents {
      url = url.deletingLastPathComponent()
    }
    return url
  }
}

internal let _packageRoot = URL(fileURLWithPath: #filePath)._deletingLastPathComponent(5)
internal let _sourcesDirectory = _packageRoot.appendingPathComponent("Sources", isDirectory: true)
internal let _mainModuleDirectory = _sourcesDirectory.appendingPathComponent("NetworkGear", isDirectory: true)
internal let _httpModuleDirectory = _mainModuleDirectory.appendingPathComponent("HTTP", isDirectory: true)

