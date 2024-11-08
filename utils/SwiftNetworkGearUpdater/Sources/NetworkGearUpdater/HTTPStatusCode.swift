/* *************************************************************************************************
 HTTPStatusCode.swift
   © 2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import CSV
import Foundation
import StringComposition
import yCodeUpdater

public final class HTTPStatusCode: HTTPUpdaterDelegate {
  public override var identifier: String {
    return "HTTPStatusCode"
  }

  public override var sourceURLs: Array<URL> {
    return [
      URL(string: "https://www.iana.org/assignments/http-status-codes/http-status-codes-1.csv")!,
    ]
  }

  public override func convert<S>(_ intermediates: S) throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<CSVReader> {
    let codes: [(UInt16, String)] = intermediates.flatMap({ $0.content.rows() }).compactMap {
      guard let code = UInt16($0[0]!) else { return nil }
      guard $0[1] != "Unassigned" && $0[1] != "(Unused)" else { return nil }
      return (code, $0[1]!)
    }
   
    var lines = StringLines()

    let typeName = "HTTPStatusCode"
    
    lines.append("public enum \(typeName): UInt16, Sendable {")
    for (value, desc) in codes {
      lines.append(String.Line("case \(desc.lowerCamelCase.swiftIdentifier) = \(value)", indentLevel: 1)!)
    }
    lines.append("}")
    
    lines.append("extension \(typeName) {")
    lines.append(String.Line("public var reasonPhrase: String {", indentLevel: 1)!)
    lines.append(String.Line("switch self {", indentLevel: 2)!)
    for (_, desc) in codes {
      lines.append(String.Line("case .\(desc.lowerCamelCase): return \(desc.debugDescription)", indentLevel: 2)!)
    }
    lines.append(String.Line("}", indentLevel: 2)!)
    lines.append(String.Line("}", indentLevel: 1)!)
    lines.append("}")

    return lines.data(using: .utf8)!
  }
}
