/* *************************************************************************************************
 MIMEType+PathExtension.swift
   © 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
import NetworkGear
import StringComposition
import yCodeUpdater
import yExtensions

private extension Optional where Wrapped: Comparable {
  static func <(lhs: Optional<Wrapped>, rhs: Optional<Wrapped>) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil): return false
    case (nil, _): return true
    case (_, nil): return false
    case (let lWrapped?, let rWrapped?): return lWrapped < rWrapped
    }
  }
  
  static func >(lhs: Optional<Wrapped>, rhs: Optional<Wrapped>) -> Bool {
    return lhs != rhs && !(lhs < rhs)
  }
}

private extension MIMEType {
  static func <(lhs: MIMEType, rhs: MIMEType) -> Bool {
    if lhs.type < rhs.type { return true }
    if lhs.type > rhs.type { return false }
    if lhs.tree < rhs.tree { return true }
    if lhs.tree > rhs.tree { return false }
    if lhs.subtype < rhs.subtype { return true }
    if lhs.subtype > rhs.subtype { return false }
    return lhs.suffix < rhs.suffix
  }
}

public struct _TypeExt: Equatable {
  public let mimeType: MIMEType
  public let extensions: ArraySlice<Substring>
}

public final class MIMETypePathExtension: CodeUpdaterDelegate {
  public init() {}
  
  public typealias IntermediateDataType = [_TypeExt]
  
  public var identifier: String {
    return "MIMEType+PathExtension"
  }
  
  public var sourceURLs: Array<URL> {
    return [
      URL(string: "https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types")!
    ]
  }
  
  public var destinationURL: URL {
    return _httpModuleDirectory.appendingPathComponent(self.identifier).appendingPathExtension("swift")
  }
  
  public func prepare(sourceURL: URL) throws -> IntermediateDataContainer<IntermediateDataType> {
    var pairs: [_TypeExt] = []
    
    let data = content(of: sourceURL)
    
    var buffer = Data()
    
    func _append() {
      if buffer.isEmpty { return }
      guard let string = String(data: buffer, encoding: .utf8) else { fatalError("Unexpected Data.") }
      let splitted = string.split { $0.isWhitespace }
      guard splitted.count >= 2, !splitted[0].hasPrefix("#") else { return }
      guard let mimeType = MIMEType(splitted[0]) else {
        view(message: "\"\(splitted[0])\" is not valid for MIMEType.")
        return
      }
      pairs.append(.init(mimeType: mimeType, extensions: splitted[1...]))
    }
    
    for byte in data {
      buffer.append(byte)
      if byte == 0x0A || byte == 0x0D {
        _append()
        buffer = Data()
      }
    }
    _append()
    
    return .init(content: pairs)
  }
  
  public func convert<S>(_ intermediates: S) throws -> Data where S: Sequence, S.Element == IntermediateDataContainer<IntermediateDataType> {
    var extensions: Set<String> = []
    var mimeTypeToExt: [MIMEType: [String]] = [:]
    var extToMIMEType: [String: MIMEType] = [:]
    
    for interm in intermediates {
      for pair in interm.content {
        let lowercasedExtensions = pair.extensions.map({ $0.lowercased() }).sorted()
        
        mimeTypeToExt[pair.mimeType] = lowercasedExtensions
        for ext in lowercasedExtensions {
          extensions.insert(ext)
          extToMIMEType[ext] = pair.mimeType
        }
      }
    }
    
    let sortedExtensions = extensions.sorted()
    let sortedMIMETypes = mimeTypeToExt.keys.sorted(by: <)
    
    var lines = StringLines()
    
    func _extIdentifier(of pathExtension: String) -> String {
      let ext = pathExtension.lowerCamelCase
      if !pathExtension.first!.isLetter {
        return "_\(ext)"
      }
      return ext.swiftIdentifier
    }
    
    do { // enum
      lines.append("extension MIMEType {")
      lines.append(String.Line("public enum PathExtension: String {", indentLevel: 1)!)
      for ext in sortedExtensions {
        lines.append(String.Line(" case \(_extIdentifier(of: ext)) = \(ext.debugDescription)", indentLevel: 2)!)
      }
      lines.append(String.Line("}", indentLevel: 1)!)
      lines.append("}")
      lines.appendEmptyLine()
    }
    
    func _mimeTypeCoreDescription(of mimeType: MIMEType) -> String {
      var result = "MIMEType._Core("
      result += "type: .\(String(describing: mimeType.type)), "
      result += "tree: " + (mimeType.tree.flatMap({ ".\(String(describing: $0))" }) ?? "nil") + ", "
      result += "subtype: \(mimeType.subtype.debugDescription), "
      result += "suffix: " + (mimeType.suffix.flatMap({ ".\(String(describing: $0))" }) ?? "nil")
      result += ")"
      return result
    }
    
    do { // MIMEType -> PathExtension
      lines.append("internal let _mimeType_to_ext: [MIMEType._Core: Set<MIMEType.PathExtension>] = [")
      for mimeType in sortedMIMETypes {
        let extensions = mimeTypeToExt[mimeType]!
        let mimeTypeDesc = _mimeTypeCoreDescription(of: mimeType)
        let extDesc = "[" + extensions.map({ "." + _extIdentifier(of: $0) }).joined(separator: ", ") + "]"
        lines.append(String.Line("\(mimeTypeDesc): \(extDesc),", indentLevel: 1)!)
      }
      lines.append("]")
    }
    
    do { // PathExtension -> MIMEType
      lines.append("internal let _ext_to_mimeType: [MIMEType.PathExtension: MIMEType._Core] = [")
      for ext in sortedExtensions {
        let mimeType = extToMIMEType[ext]!
        let mimeTypeDesc = _mimeTypeCoreDescription(of: mimeType)
        lines.append(String.Line(".\(_extIdentifier(of: ext)): \(mimeTypeDesc),", indentLevel: 1)!)
      }
      lines.append("]")
    }
    
    return lines.data(using: .utf8)!
  }
}
