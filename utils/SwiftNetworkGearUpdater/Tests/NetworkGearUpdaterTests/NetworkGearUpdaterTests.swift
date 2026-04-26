/* *************************************************************************************************
 NetworkGearUpdaterTests.swift
  © 2020,2024,2026 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import NetworkGearUpdater
import yCodeUpdater
import Testing

private func _lines<D>(with delegate: D) async throws -> [Substring] where D: CodeUpdaterDelegate {
  var containers: [IntermediateDataContainer<D.IntermediateDataType>] = []
  for url in delegate.sourceURLs {
    containers.append(try await delegate.prepare(sourceURL: url))
  }
  let data =  try await delegate.convert(containers)
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


@Suite final class NetworkGearUpdaterTests {
  @Test func test_ContentDispositionValue() async throws {
    let lines = try await _lines(with: ContentDispositionValue())
    #expect(lines._contains(line: "case attachment = \"attachment\""))
    #expect(lines._contains(line: "case \"attachment\": self = .attachment"))
  }

  @Test func test_HTTPMethod() async throws {
    let lines = try await _lines(with: HTTPMethod())
    #expect(lines._contains(line: "case get = \"GET\""))
    #expect(lines._contains(line: "case \"get\": self = .get"))
  }

  @Test func test_HTTPStatusCode() async throws {
    let lines = try await _lines(with: HTTPStatusCode())
    #expect(lines._contains(line: "case ok = 200"))
    #expect(lines._contains(line: "case .notFound: return \"Not Found\""))
  }

  @Test func test_IANARegisteredContentDispositionParameterKey() async throws {
    let lines = try await _lines(with: IANARegisteredContentDispositionParameterKey())
    #expect(lines._contains(line: "public static let filename = ContentDispositionParameterKey(rawValue: \"filename\")"))
  }

  @Test func test_IANARegisteredHTTPHeaderFieldName() async throws {
    let lines = try await _lines(with: IANARegisteredHTTPHeaderFieldName())
    #expect(lines._contains(line: "public static let contentEncoding = HTTPHeaderFieldName(rawValue: \"Content-Encoding\")"))
    #expect(lines._contains(line: "public static let contentTransferEncoding = HTTPHeaderFieldName(rawValue: \"Content-Transfer-Encoding\")"))
  }

  @Test func test_MIMETypePathExtension() async throws {
    let lines = try await _lines(with: MIMETypePathExtension())
    #expect(lines._contains(line: "case text = \"text\""))
    #expect(lines._contains(line: "MIMEType._Core(type: .text, tree: nil, subtype: \"html\", suffix: nil): [.html, .htm],"))
    #expect(lines._contains(line: ".aiff: MIMEType._Core(type: .audio, tree: nil, subtype: \"x-aiff\", suffix: nil),"))
  }
}
