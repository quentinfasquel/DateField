//
//  NumberFieldTests.swift
//  DateFieldTests
//
//  Created by Quentin Fasquel on 10/12/2019.
//  Copyright © 2019 Quentin Fasquel. All rights reserved.
//

import XCTest
@testable import DateField

class NumberFieldTests: XCTestCase {
    
    var sut: NumberField!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = NumberField()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func simulateBeginEditing() {
        _ = sut.textField.delegate?.textFieldShouldBeginEditing?(sut.textField)
    }
    
    func simulateTap(digit: Character) {
        let range = NSRange(location: sut.textField.text?.count ?? 0, length: 0)
        _ = sut.textField.delegate?.textField?(sut.textField, shouldChangeCharactersIn: range, replacementString: String(digit)) ?? false
    }
    
    func simulateTap(digits: Character...) {
        digits.forEach { simulateTap(digit: $0) }
    }

    func testInitWithFrame() {
        // Test default values
        XCTAssertEqual(sut.numberOfDigits, 2)
        XCTAssertEqual(sut.maxValue, 99)
        XCTAssertEqual(sut.minValue, 1)
        XCTAssertEqual(sut.value, sut.minValue)
        XCTAssertFalse(sut.allowsDeletionAfterReachingCount)
        XCTAssertNil(sut.inputCompletionHandler)
    }
    
    func testMaxValue() {
        sut.maxValue = 10
        XCTAssertEqual(sut.maxValue, 10)
        sut.value = 12
        XCTAssertEqual(sut.value, sut.maxValue)
        sut.maxValue = 9
        XCTAssertEqual(sut.value, 9)
    }

    func testMinValue() {
        sut.minValue = 5
        XCTAssertEqual(sut.minValue, 5)
        sut.value = 2
        XCTAssertEqual(sut.value, sut.minValue)
        sut.minValue = 6
        XCTAssertEqual(sut.value, 6)
    }
    
    func testDigitLabels() {
        simulateBeginEditing()
        simulateTap(digit: "5")
        XCTAssertEqual(sut.textField.text, "5")
    }
    
    func testInputCompletionNumberOfDigits() {
        let numberOfDigitsReached = expectation(description: "numberOfDigits reached, completing input")

        sut.maxValue = 99
        sut.numberOfDigits = 2
        sut.value = 1
        sut.inputCompletionHandler = { remainder in
            XCTAssertEqual(remainder, 1)
            numberOfDigitsReached.fulfill()
        }

        sut.allowsDeletionAfterReachingCount = true

        simulateBeginEditing()
        simulateTap(digits: "5", "5", "1")
        wait(for: [numberOfDigitsReached], timeout: 1)
    }
    
    func testInputCompletionCompleteOnReachCount() {
//        sut.maxValue = 99
//        sut.numberOfDigits = 2
//        sut.value = 1
//        sut.inputCompletionHandler = { remainder in
//            XCTAssertEqual(remainder, 0)
//        }
    }
    
    func testInputCompletionMaxValue() {
        let maxValueReached = expectation(description: "maxValue reached, completing input")
        
        sut.maxValue = 10
        sut.numberOfDigits = 2
        sut.value = 1
        sut.inputCompletionHandler = { nextValue in
            XCTAssertEqual(nextValue, 2)
            maxValueReached.fulfill()
        }

        simulateBeginEditing()
        simulateTap(digits: "1", "2")
        wait(for: [maxValueReached], timeout: 1)
    }
    

}
