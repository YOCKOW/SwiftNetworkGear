/* *************************************************************************************************
 HTTPMethod.swift
   © 2020,2024,2026 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
@preconcurrency import CSV
import Foundation
import StringComposition
import yCodeUpdater
import yExtensions

private extension StringProtocol {
  var _methodLowerCamelCase: String {
    return self.lowercased().lowerCamelCase
  }

  var _quoted: String {
    var resultUTF8 = Data()
    resultUTF8.append(0x22)

    for byte in self.utf8 {
      if byte == 0x22 || byte == 0x5C {
        resultUTF8.append(contentsOf: [0x5C, byte])
      } else {
        resultUTF8.append(byte)
      }
    }

    resultUTF8.append(0x22)
    return String(data: resultUTF8, encoding: .utf8)!
  }
}

public final class HTTPMethod: HTTPUpdaterDelegate {
  public init() {}
  
  public var identifier: String {
    return "HTTPMethod"
  }
  
  public var sourceURLs: Array<URL> {
    return [
      URL(string: "https://www.iana.org/assignments/http-methods/methods.csv")!,
    ]
  }
  
  public func convert<S>(_ intermediates: S) async throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<CSVReader> {
    let methods: [String] = intermediates.flatMap({ $0.content.rows() }).compactMap {
      let method = $0[0]!
      guard method.allSatisfy({ $0.isLetter || $0 == "-" }) else { return nil }
      return method
    }
    
    var lines = StringLines()
    
    let typeName = "HTTPMethod"
    let stringTypeName = "HTTPMethodString"
    let otherMethodCase = "otherMethod"

    lines.append("import yExtensions")
    lines.appendEmptyLine()

    DEFINE: do {
      lines.append("public enum \(typeName): Sendable {")
      for method in methods {
        lines.append(String.Line("case \(try await method._methodLowerCamelCase.swiftIdentifier)", indentLevel: 1)!)
      }
      lines.append(String.Line("case \(otherMethodCase)(\(stringTypeName))", indentLevel: 1)!)
      lines.append("}")
      lines.appendEmptyLine()
    }

    EQUATABLE: do {
      lines.append("extension \(typeName): Equatable {")
      lines.append(String.Line("public static func ==(lhs: \(typeName), rhs: \(typeName)) -> Bool {", indentLevel: 1)!)
      lines.append(String.Line("switch (lhs, rhs) {", indentLevel: 2)!)
      for method in methods {
        let identifier = method._methodLowerCamelCase
        lines.append(String.Line("case (.\(identifier), .\(identifier)): return true", indentLevel: 2)!)
      }
      lines.append(String.Line("case (.\(otherMethodCase)(let lstr), .\(otherMethodCase)(let rstr)): return lstr == rstr", indentLevel: 2)!)
      lines.append(String.Line("default: return false", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 1)!)
      lines.append("}")
      lines.appendEmptyLine()
    }

    RAW_REPRESENTABLE: do {
      lines.append("extension \(typeName): RawRepresentable {")
      lines.append(String.Line("public typealias RawValue = String", indentLevel: 1)!)
      lines.appendEmptyLine()
      lines.append(String.Line("public var rawValue: String {", indentLevel: 1)!)
      lines.append(String.Line("switch self {", indentLevel: 2)!)
      for method in methods {
        lines.append(String.Line("case .\(method._methodLowerCamelCase): return \(method._quoted)", indentLevel: 2)!)
      }
      lines.append(String.Line("case .\(otherMethodCase)(let string): return string.description", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 1)!)
      lines.appendEmptyLine()

      lines.append(String.Line("public init?(rawValue: String) {", indentLevel: 1)!)
      for method in methods {
        lines.append(String.Line("if rawValue.isASCIICaseInsensitivelyEqual(to: \(method._quoted)) {", indentLevel: 2)!)
        lines.append(String.Line("self = .\(method._methodLowerCamelCase); return", indentLevel: 3)!)
        lines.append(String.Line("}", indentLevel: 2)!)
      }
      lines.append(String.Line("if let string = \(stringTypeName)(rawValue) {", indentLevel: 2)!)
      lines.append(String.Line("self = .\(otherMethodCase)(string); return", indentLevel: 3)!)
      lines.append(String.Line("}", indentLevel: 2)!)
      lines.append(String.Line("return nil", indentLevel: 2)!)
      lines.append(String.Line("}", indentLevel: 1)!)
      lines.append("}")
    }

    return lines.data(using: .utf8)!
  }
}
