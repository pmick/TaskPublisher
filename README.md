# TaskPublisher

A publisher that executes an async function.

```swift
searchTextPublisher
    .removeDuplicates()
    .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
    .map { query in
        TaskPublisher {
            return try await httpClient.searchUsers(query)
        }
        .handleEvents(receiveCompletion: { completion in
            if case .failure = completion {
                // Show some error UI
            }
        })
        // Prevent outer publisher from failing so that future searches work
        .replaceError(with: [])
    }
    .switchToLatest()
    .sink { [weak self] users in
        self?.applySnapshot(users)
    }
    .store(in: &bag)
```