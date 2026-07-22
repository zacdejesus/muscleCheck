//
//  ArrayExtensionTests.swift
//  MuscleCheck
//
//  Covers the safe subscript used in the entry-deletion paths and appendIfNotNil.
//

import Testing
@testable import MuscleCheck

struct ArrayExtensionTests {

    @Test
    func testSafeSubscriptReturnsElementInBounds() {
        let arr = ["a", "b", "c"]
        #expect(arr[safe: 0] == "a")
        #expect(arr[safe: 2] == "c")
    }

    @Test
    func testSafeSubscriptOutOfBoundsReturnsNil() {
        let arr = ["a", "b", "c"]
        #expect(arr[safe: 3] == nil)
        #expect(arr[safe: -1] == nil)
    }

    @Test
    func testSafeSubscriptOnEmptyArrayReturnsNil() {
        let arr: [Int] = []
        #expect(arr[safe: 0] == nil)
    }

    @Test
    func testAppendIfNotNilAppendsValue() {
        var arr = [1, 2]
        arr.appendIfNotNil(3)
        #expect(arr == [1, 2, 3])
    }

    @Test
    func testAppendIfNotNilSkipsNil() {
        var arr = [1, 2]
        let value: Int? = nil
        arr.appendIfNotNil(value)
        #expect(arr == [1, 2])
    }
}
