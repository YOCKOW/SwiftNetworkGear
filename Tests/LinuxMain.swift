import XCTest

import HTTPTests
import NetworkGearTests

var tests = [XCTestCaseEntry]()
tests += HTTPTests.__allTests()
tests += NetworkGearTests.__allTests()

XCTMain(tests)
