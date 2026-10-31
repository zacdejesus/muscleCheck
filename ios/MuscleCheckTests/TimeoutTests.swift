//
//  TimeoutTests.swift
//  MuscleCheckTests
//

import Testing
@testable import MuscleCheck
import Foundation

struct TimeoutTests {

    @Test
    func returnsTheResultWhenTheOperationFinishesInTime() async throws {
        let value = try await withTimeout(.seconds(2)) { 42 }
        #expect(value == 42)
    }

    @Test
    func rethrowsTheOperationsOwnError() async {
        struct Boom: Error {}
        await #expect(throws: Boom.self) {
            try await withTimeout(.seconds(2)) { throw Boom() }
        }
    }

    @Test
    func throwsTimeoutWhenTheOperationIsTooSlow() async {
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(.milliseconds(50)) {
                try await Task.sleep(for: .seconds(5))
                return 1
            }
        }
    }

    @Test
    func resumesAtTheDeadlineEvenIfTheOperationIgnoresCancellation() async throws {
        // The PCC request might not stop when cancelled; the caller must not wait for it.
        let clock = ContinuousClock()
        let start = clock.now
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(.milliseconds(50)) {
                let end = ContinuousClock.now + .seconds(2)
                while ContinuousClock.now < end { await Task.yield() }
                return 1
            }
        }
        #expect(clock.now - start < .seconds(1))
    }

    @Test
    func cancelsTheOperationOnTimeout() async throws {
        let wasCancelled = Flag()
        _ = try? await withTimeout(.milliseconds(50)) {
            do {
                try await Task.sleep(for: .seconds(5))
            } catch is CancellationError {
                wasCancelled.set()
            }
            return 1
        }
        try await Task.sleep(for: .milliseconds(200))
        #expect(wasCancelled.value)
    }
}

private final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false
    var value: Bool { lock.lock(); defer { lock.unlock() }; return flag }
    func set() { lock.lock(); flag = true; lock.unlock() }
}
