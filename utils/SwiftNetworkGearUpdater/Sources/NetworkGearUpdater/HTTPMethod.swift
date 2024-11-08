/* *************************************************************************************************
 HTTPMethod.swift
   © 2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import CSV
import Foundation
import StringComposition
import yCodeUpdater
import yExtensions

private extension StringProtocol {
  var _methodLowerCamelCase: String {
    return self.lowercased().lowerCamelCase
  }
}

public final class HTTPMethod: HTTPUpdaterDelegate {
  public override var identifier: String {
    return "HTTPMethod"
  }
  
  public override var sourceURLs: Array<URL> {
    return [
      URL(string: "https://www.iana.org/assignments/http-methods/methods.csv")!,
    ]
  }
  
  public override func convert<S>(_ intermediates: S) throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<CSVReader> {
    let methods: [String] = intermediates.flatMap({ $0.content.rows() }).compactMap {
      let method = $0[0]!
      guard method.allSatisfy({ $0.isLetter || $0 == "-" }) else { return nil }
      return method
    }
    
    var lines = StringLines()
    
    let typeName = "HTTPMethod"
    
    lines.append("public enum \(typeName): String, Sendable {")
    for method in methods {
      lines.append(String.Line("case \(method._methodLowerCamelCase.swiftIdentifier) = \(method.debugDescription)", indentLevel: 1)!)
    }
    lines.append("}")
    lines.appendEmptyLine()
    
    lines.append("extension \(typeName) {")
    lines.append(String.Line("public init?(rawValue: String) {", indentLevel: 1)!)
    lines.append(String.Line("switch rawValue.lowercased() {", indentLevel: 2)!)
    for method in methods {
      lines.append(String.Line("case \(method.lowercased().debugDescription): self = .\(method._methodLowerCamelCase)", indentLevel: 2)!)
    }
    lines.append(String.Line("default: return nil", indentLevel: 2)!)
    lines.append(String.Line("}", indentLevel: 2)!)
    lines.append(String.Line("}", indentLevel: 1)!)
    lines.append("}")
    
    return lines.data(using: .utf8)!
  }
}
