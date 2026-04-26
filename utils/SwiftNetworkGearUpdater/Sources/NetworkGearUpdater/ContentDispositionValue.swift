/* *************************************************************************************************
 ContentDispositionValue.swift
   © 2020,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@preconcurrency import CSV
import Foundation
import StringComposition
import yCodeUpdater
import yExtensions

public final class ContentDispositionValue: HTTPUpdaterDelegate {
  public init() {}

  public var identifier: String {
    return "ContentDispositionValue"
  }
  
  public var sourceURLs: Array<URL> {
    return [
      URL(string: "https://www.iana.org/assignments/cont-disp/cont-disp-1.csv")!,
    ]
  }
  
  public func convert<S>(_ intermediates: S) async throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<CSVReader> {
    let values: [String] = intermediates.flatMap({ $0.content.rows() }).compactMap {
      let value = $0[0]!
      guard value.allSatisfy({ $0.isLowercase || $0 == "-" }) else { return nil }
      return value
    }
    
    var lines = StringLines()
    
    let typeName = "ContentDispositionValue"
    
    lines.append("public enum \(typeName): String, Sendable {")
    for value in values {
      lines.append(String.Line("case \(try await value.lowerCamelCase.swiftIdentifier) = \(value.debugDescription)", indentLevel: 1)!)
    }
    lines.append("}")
    lines.appendEmptyLine()
    
    lines.append("extension \(typeName) {")
    lines.append(String.Line("public init(rawValue: String) {", indentLevel: 1)!)
    lines.append(String.Line("switch rawValue.lowercased() {", indentLevel: 2)!)
    for value in values {
      lines.append(String.Line("case \(value.lowercased().debugDescription): self = .\(value.lowerCamelCase)", indentLevel: 2)!)
    }
    lines.append(String.Line("default: self = .attachment", indentLevel: 2)!)
    lines.append(String.Line("}", indentLevel: 2)!)
    lines.append(String.Line("}", indentLevel: 1)!)
    lines.append("}")
    
    return lines.data(using: .utf8)!
  }
}

