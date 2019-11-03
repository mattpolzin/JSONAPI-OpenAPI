import XCTest

import JSONAPIOpenAPITests
import JSONAPISwiftGenTests

var tests = [XCTestCaseEntry]()
tests += JSONAPIOpenAPITests.__allTests()
tests += JSONAPISwiftGenTests.__allTests()

XCTMain(tests)
