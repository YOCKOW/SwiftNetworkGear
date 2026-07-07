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
    let otherCaseName = "dispositionType"

    lines.append("import yExtensions")
    lines.appendEmptyLine()

    lines.append("public enum \(typeName): Sendable {")
    for value in values {
      lines.append(String.Line("case \(try await value.lowerCamelCase.swiftIdentifier)", indentLevel: 1)!)
    }
    lines.append(String.Line("case \(otherCaseName)(ASCIICaseInsensitiveHTTPTokenString)", indentLevel: 1)!)
    lines.append("}")
    lines.appendEmptyLine()

    // To avoid circular reference, implement `Hashable` conformance.
    HASHABLE: do {
      lines.append("extension \(typeName): Equatable, Hashable {")

      lines.append(String.Line("public static func ==(lhs: \(typeName), rhs: \(typeName)) -> Bool {", indentLevel: 1)!)
      lines.append(String.Line("switch (lhs, rhs) {", indentLevel: 2)!)
      for value in values {
        let id = try await value.lowerCamelCase.swiftIdentifier
        lines.append(String.Line("case (.\(id), .\(id)): return true", indentLevel: 2)!)
      }
      lines.append(String.Line("case (.\(otherCaseName)(let lStr), .\(otherCaseName)(let rStr)): return lStr == rStr", indentLevel: 2)!)
      lines.append(String.Line("default: return false", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 1)!)
      lines.appendEmptyLine()

      lines.append(String.Line("public func hash(into hasher: inout Hasher) {", indentLevel: 1)!)
      lines.append(String.Line("switch self {", indentLevel: 2)!)
      for (ii, value) in values.enumerated() {
        lines.append(String.Line("case .\(try await value.lowerCamelCase.swiftIdentifier): hasher.combine(\(ii))", indentLevel: 2)!)
      }
      lines.append(String.Line("case .\(otherCaseName)(let str): hasher.combine(str)", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 1)!)

      lines.append("}")
      lines.appendEmptyLine()
    }

    CASE_TO_STRING: do {
      lines.append("extension \(typeName) {")
      lines.append(String.Line("@usableFromInline internal static let _registeredCaseToString: [\(typeName): String] = [", indentLevel: 1)!)
      for value in values {
        lines.append(String.Line(".\(try await value.lowerCamelCase.swiftIdentifier): \(value.debugDescription),", indentLevel: 2)!)
      }
      lines.append(String.Line("]", indentLevel: 1)!)
      lines.append("}")
      lines.appendEmptyLine()
    }

    STRING_TO_CASE: do {
      lines.append("extension \(typeName) {")
      lines.append(String.Line("@inlinable internal static func _stringToRegisteredCase<S>(_ string: S) -> \(typeName)? where S: StringProtocol {", indentLevel: 1)!)
      for (ii, value) in values.enumerated() {
        if ii == 0 {
          lines.append(String.Line("if string.isASCIICaseInsensitivelyEqual(to: \(value.debugDescription)) {", indentLevel: 2)!)
        } else {
          lines.append(String.Line("} else if string.isASCIICaseInsensitivelyEqual(to: \(value.debugDescription)) {", indentLevel: 2)!)
        }
        lines.append(String.Line("return .\(try await value.lowerCamelCase.swiftIdentifier)", indentLevel: 3)!)
      }
      lines.append(String.Line("} else {", indentLevel: 2)!)
      lines.append(String.Line("return nil", indentLevel: 3)!)
      lines.append(String.Line("}", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 1)!)
      lines.append("}")
      lines.appendEmptyLine()
    }

    return lines.data(using: .utf8)!
  }
}

