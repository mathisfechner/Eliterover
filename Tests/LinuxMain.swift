//
// Created by max on 05.12.20.
//

import Foundation

import XCTest

import tryTests

var tests = [XCTestCaseEntry]()
tests += tryTests.allTests()
XCTMain(tests)