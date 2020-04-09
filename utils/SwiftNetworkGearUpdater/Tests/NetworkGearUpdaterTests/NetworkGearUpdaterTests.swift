/* *************************************************************************************************
 NetworkGearUpdaterTests.swift
  © 2020 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import NetworkGearUpdater

import yCodeUpdater

private func _lines<D>(with delegate: D) throws -> [Substring] where D: CodeUpdaterDelegate {
  let data =  try delegate.convert(delegate.sourceURLs.map({ try delegate.prepare(sourceURL: $0) }))
  let string = String(data: data, encoding: .utf8)!
  return string.split { $0.isNewline }
}

private extension Substring {
  func _trimmed() -> Substring {
    guard let si = self.firstIndex(where: { !$0.isWhitespace }) else { return "" }
    let ei = self.lastIndex(where: { !$0.isWhitespace })!
    return self[si...ei]
  }
}

private extension Array where Element == Substring {
  func _contains(line: Substring) -> Bool {
    for line in self {
      if line._trimmed() == line { return true }
    }
    return false
  }
}

final class NetworkGearUpdaterTests: XCTestCase {
  func test_ContentDispositionValue() throws {
    let lines = try _lines(with: ContentDispositionValue())
    XCTAssertTrue(lines._contains(line: "case attachment = \"attachment\""))
    XCTAssertTrue(lines._contains(line: "case \"attachment\": self = .attachment"))
  }
  
  func test_HTTPMethod() throws {
    let lines = try _lines(with: HTTPMethod())
    XCTAssertTrue(lines._contains(line: "case get = \"GET\""))
    XCTAssertTrue(lines._contains(line: "case \"get\": self = .get"))
  }
  
  func test_HTTPStatusCode() throws {
    let lines = try _lines(with: HTTPStatusCode())
    print(lines.joined(separator: "\n"))
    XCTAssertTrue(lines._contains(line: "case ok = 200"))
    XCTAssertTrue(lines._contains(line: "case .notFound: return \"Not Found\""))
  }
  
  func test_IANARegisteredContentDispositionParameterKey() throws {
    let lines = try _lines(with: IANARegisteredContentDispositionParameterKey())
    XCTAssertTrue(lines._contains(line: "public static let filename = ContentDispositionParameterKey(rawValue: \"filename\")"))
  }
  
  func test_IANARegisteredHTTPHeaderFieldName() throws {
    let lines = try _lines(with: IANARegisteredHTTPHeaderFieldName())
    XCTAssertTrue(lines._contains(line: "public static let contentEncoding = HTTPHeaderFieldName(rawValue: \"Content-Encoding\")"))
    XCTAssertTrue(lines._contains(line: "public static let contentTransferEncoding = HTTPHeaderFieldName(rawValue: \"Content-Transfer-Encoding\")"))
  }
  
  func test_MIMETypePathExtension() throws {
    let lines = try _lines(with: MIMETypePathExtension())
    print(lines.joined(separator: "\n"))
    XCTAssertTrue(lines._contains(line: "case text = \"text\""))
    XCTAssertTrue(lines._contains(line: "MIMEType._Core(type: .text, tree: nil, subtype: \"html\", suffix: nil): [.html, .htm],"))
    XCTAssertTrue(lines._contains(line: ".aiff: MIMEType._Core(type: .audio, tree: nil, subtype: \"x-aiff\", suffix: nil),"))
  }
}
