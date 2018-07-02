import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(CTests.allTests),
    testCase(DomainLabelTests.allTests),
    testCase(DomainPublicSuffixTests.allTests),
    testCase(DomainTests.allTests),
    testCase(URLHostTests.allTests),
    testCase(URLIDNATests.allTests),
  ]
}
#endif
