import XCTest

import HTTPTests
import NetworkTests

var tests = [XCTestCaseEntry]()
tests += HTTPTests.__allTests()
tests += NetworkTests.__allTests()

XCTMain(tests)
