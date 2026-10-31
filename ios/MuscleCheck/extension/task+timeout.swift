//
//  task+timeout.swift
//  MuscleCheck
//
//  A deadline for async work, used by the AI Coach so a slow Private Cloud
//  Compute request falls back to the on-device model instead of hanging.
//

import Foundation

struct TimeoutError: Error, Equatable {}

/// Runs `operation` and returns its result, or throws `TimeoutError` once `timeout`
/// elapses — whichever comes first. On timeout the operation is cancelled.
///
/// Not a task group on purpose: a group waits for every child before returning, so
/// an operation that ignores cancellation would hold the caller past the deadline.
/// Here the caller resumes at the deadline and a late result is discarded.
func withTimeout<T: Sendable>(
    _ timeout: Duration,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let gate = ResumeOnce<T>()
    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            gate.attach(continuation)
            let work = Task {
                do { gate.resume(with: .success(try await operation())) }
                catch { gate.resume(with: .failure(error)) }
            }
            let timer = Task {
                try await Task.sleep(for: timeout)
                work.cancel()
                gate.resume(with: .failure(TimeoutError()))
            }
            gate.onResume { timer.cancel() }
        }
    } onCancel: {
        gate.resume(with: .failure(CancellationError()))
    }
}

/// Resumes a continuation exactly once, from whichever side finishes first. A result
/// that arrives before the continuation is attached (cancellation can) is held for it.
private final class ResumeOnce<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Error>?
    private var result: Result<T, Error>?
    private var didResume = false
    private var cleanup: (() -> Void)?

    func attach(_ continuation: CheckedContinuation<T, Error>) {
        lock.lock()
        if let result {
            didResume = true
            lock.unlock()
            continuation.resume(with: result)
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    func onResume(_ cleanup: @escaping () -> Void) {
        lock.lock()
        if didResume {
            lock.unlock()
            cleanup()
            return
        }
        self.cleanup = cleanup
        lock.unlock()
    }

    func resume(with result: Result<T, Error>) {
        lock.lock()
        guard !didResume, self.result == nil else { lock.unlock(); return }
        guard let continuation else {
            self.result = result
            lock.unlock()
            return
        }
        didResume = true
        let cleanup = self.cleanup
        self.continuation = nil
        self.cleanup = nil
        lock.unlock()
        continuation.resume(with: result)
        cleanup?()
    }
}
