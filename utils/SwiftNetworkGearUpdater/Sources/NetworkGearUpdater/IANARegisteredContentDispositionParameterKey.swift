/* *************************************************************************************************
 IANARegisteredContentDispositionParameterKey.swift
   © 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import CSV
import Foundation
import StringComposition
import yCodeUpdater
import yExtensions

public final class IANARegisteredContentDispositionParameterKey: HTTPUpdaterDelegate {
  public override var identifier: String {
    return "ContentDispositionParameterKey+IANARegistered"
  }
  
  public override var sourceURLs: Array<URL> {
    return [
      URL(string: "https://www.iana.org/assignments/cont-disp/cont-disp-2.csv")!,
    ]
  }
  
  public override func convert<S>(_ intermediates: S) throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<CSVReader> {
    let names: [String] = intermediates.flatMap({ $0.content.rows() }).compactMap {
      let name = $0[0]!
      guard name.allSatisfy({ $0.isLowercase || $0 == "-" }) else { return nil }
      return name
    }
    
    var lines = StringLines()
    
    let typeName = "ContentDispositionParameterKey"
    lines.append("extension \(typeName) {")
    for name in names {
      lines.append(String.Line("public static let \(name.lowerCamelCase.swiftIdentifier) = \(typeName)(rawValue: \(name.debugDescription))", indentLevel: 1)!)
    }
    lines.append("}")
    
    return lines.data(using: .utf8)!
  }
}
