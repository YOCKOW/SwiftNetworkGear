/* *************************************************************************************************
 HTTPHeaderFieldParameterName+IANARegisteredContentDispositionParameterKey.swift
   © 2020,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@preconcurrency import CSV
import Foundation
import StringComposition
import yCodeUpdater
import yExtensions

public final class IANARegisteredContentDispositionParameterKey: HTTPUpdaterDelegate {
  public init() {}

  public var identifier: String {
    return "HTTPHeaderFieldParameterName+IANARegisteredContentDispositionParameterKey"
  }
  
  public var sourceURLs: Array<URL> {
    return [
      URL(string: "https://www.iana.org/assignments/cont-disp/cont-disp-2.csv")!,
    ]
  }
  
  public func convert<S>(_ intermediates: S) async throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<CSVReader> {
    let names: [String] = intermediates.flatMap({ $0.content.rows() }).compactMap {
      let name = $0[0]!
      guard name.allSatisfy({ $0.isLowercase || $0 == "-" }) else { return nil }
      return name
    }
    
    var lines = StringLines()

    // Regular Name
    let regularTypeName = "HTTPHeaderFieldParameter.Name"
    lines.append("extension \(regularTypeName) {")
    for name in names {
      let swiftIdentifier = try await name.lowerCamelCase.swiftIdentifier
      lines.append(String.Line("/// A regular name whose attribute is `\(name)` without section index.", indentLevel: 1)!)
      lines.append(String.Line("public static let \(swiftIdentifier) = \(regularTypeName)(_validatedAttribute: \(name.debugDescription), sectionIndex: nil)", indentLevel: 1)!)
      lines.appendEmptyLine()

      lines.append(String.Line("/// A regular name whose attribute is `\(name)` with the given section index.", indentLevel: 1)!)
      lines.append(String.Line("@inlinable", indentLevel: 1)!)
      lines.append(String.Line("public static func \(swiftIdentifier)(sectionIndex: Int?) -> \(regularTypeName) {", indentLevel: 1)!)
      lines.append(String.Line("return \(regularTypeName)(_validatedAttribute: \(name.debugDescription), sectionIndex: sectionIndex)", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 1)!)
      lines.appendEmptyLine()
    }
    lines.append("}")


    let extendedTypeName = "HTTPHeaderFieldParameter.ExtendedName"
    lines.append("extension \(extendedTypeName) {")
    for name in names {
      let swiftIdentifier = try await name.lowerCamelCase.swiftIdentifier
      lines.append(String.Line("/// A extended name whose attribute is `\(name)` without section index.", indentLevel: 1)!)
      lines.append(String.Line("public static let \(swiftIdentifier) = \(extendedTypeName)(_baseName: .\(swiftIdentifier))", indentLevel: 1)!)
      lines.appendEmptyLine()

      lines.append(String.Line("/// A extended name whose attribute is `\(name)` with the given section index.", indentLevel: 1)!)
      lines.append(String.Line("@inlinable", indentLevel: 1)!)
      lines.append(String.Line("public static func \(swiftIdentifier)(sectionIndex: Int?) -> \(extendedTypeName) {", indentLevel: 1)!)
      lines.append(String.Line("let baseName = \(regularTypeName).\(swiftIdentifier)(sectionIndex: sectionIndex)", indentLevel: 2)!)
      lines.append(String.Line("return \(extendedTypeName)(_baseName: baseName)", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 1)!)
      lines.appendEmptyLine()
    }
    lines.append("}")

    return lines.data(using: .utf8)!
  }
}
