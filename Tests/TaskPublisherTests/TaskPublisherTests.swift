import Combine
import XCTest
@testable import TaskPublisher

final class TaskPublisherTests: XCTestCase {
    func testNoSubscribers() {
        var workComplete = false
        func work() async {
            workComplete = true
        }

        _ = TaskPublisher {
            await work()
        }

        XCTAssertFalse(workComplete)
    }

    func testOneSubscriber() throws {
        func work() async -> String {
            return "Hello world!"
        }

        let expectation = expectation(description: "work")
        var capturedText: String?
        var capturedCompletion: Subscribers.Completion<Error>?
        let cancellable = TaskPublisher {
            return await work()
        }.sink(receiveCompletion: { completion in
            capturedCompletion = completion
            expectation.fulfill()
        }, receiveValue: { text in
            capturedText = text
        })

        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertEqual(capturedText, "Hello world!")

        if case .failure = try XCTUnwrap(capturedCompletion) {
            XCTFail("Expected publisher to finish, but got: \(String(describing: capturedCompletion))")
        }
    }

    func testFailure() throws {
        struct TestingError: Error {}
        func work() async throws {
            throw TestingError()
        }

        let expectation = expectation(description: "work")
        var capturedCompletion: Subscribers.Completion<Error>?
        let cancellable = TaskPublisher {
            return try await work()
        }.sink(receiveCompletion: { completion in
            capturedCompletion = completion
            expectation.fulfill()
        }, receiveValue: {})

        waitForExpectations(timeout: 3, handler: nil)

        if case let .failure(error) = try XCTUnwrap(capturedCompletion) {
            XCTAssertTrue(error is TestingError)
        } else {
            XCTFail("Expected publisher to fail, but got: \(String(describing: capturedCompletion))")
        }
    }

    func testCancellation() {
        var workCancelled = false
        let expectation = expectation(description: "work")

        func work() async {
            sleep(1)
            workCancelled = Task.isCancelled
            expectation.fulfill()
        }

        let cancellable = TaskPublisher {
            await work()
        }.sink(receiveCompletion: { _ in }, receiveValue: { })

        // Enqueue cancellation before we spin waiting for expectations and cancel sooner than work completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cancellable.cancel()
        }

        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertTrue(workCancelled)
    }
}
