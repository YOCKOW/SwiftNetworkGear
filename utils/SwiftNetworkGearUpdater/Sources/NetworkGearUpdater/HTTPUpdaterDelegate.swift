/* *************************************************************************************************
 HTTPUpdaterDelegate.swift
   © 2020,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@preconcurrency import CSV
import Foundation
import yCodeUpdater

public protocol HTTPUpdaterDelegate: CodeUpdaterDelegate where IntermediateDataType == CSVReader {}
extension HTTPUpdaterDelegate {
  public var destinationURL: URL {
    return _httpModuleDirectory.appendingPathComponent(self.identifier).appendingPathExtension("swift")
  }
}
