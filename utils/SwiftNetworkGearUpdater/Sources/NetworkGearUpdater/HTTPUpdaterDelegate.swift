/* *************************************************************************************************
 HTTPUpdaterDelegate.swift
   © 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import CSV
import Foundation
import yCodeUpdater

private func _mustBeOverridden(_ function: StaticString = #function,
                               file: StaticString = #file, line: UInt = #line) -> Never {
  fatalError("`\(function)` must be overridden.", file: file, line: line)
}

public class HTTPUpdaterDelegate: CodeUpdaterDelegate {
  public typealias IntermediateDataType = CSVReader
  
  public init() {}
  
  public var identifier: String { _mustBeOverridden() }
  
  public var sourceURLs: Array<URL> { _mustBeOverridden() }
  
  public var destinationURL: URL {
    return _httpModuleDirectory.appendingPathComponent(self.identifier).appendingPathExtension("swift")
  }
  
  public func convert<S>(_ intermediates: S) throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<CSVReader> {
    _mustBeOverridden()
  }
}
