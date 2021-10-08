import Combine

public struct TaskPublisher<Output>: Publisher {
    public typealias Failure = Error

    private let operation: () async throws -> Output

    public init(operation: @escaping () async throws -> Output) {
        self.operation = operation
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let subscription = TaskSubscription(operation: operation, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }

    final class TaskSubscription<S: Subscriber>: Subscription where S.Failure == Error {
        private let operation: () async throws -> S.Input
        private var subscriber: S?
        private var task: Task<Void, Never>?

        init(operation: @escaping () async throws -> S.Input, subscriber: S) {
            self.operation = operation
            self.subscriber = subscriber
        }

        func request(_ demand: Subscribers.Demand) {
            if demand > .none {
                task = Task {
                    do {
                        let result = try await operation()
                        _ = subscriber?.receive(result)
                        subscriber?.receive(completion: .finished)
                    } catch {
                        subscriber?.receive(completion: .failure(error))
                    }
                }
            }
        }

        func cancel() {
            subscriber = nil
            task?.cancel()
        }
    }
}
