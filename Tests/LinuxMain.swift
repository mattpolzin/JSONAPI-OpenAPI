import XCTest

import JSONAPIOpenAPITests

var tests = [XCTestCaseEntry]()
tests += JSONAPIOpenAPITests.allTests()
XCTMain(tests)