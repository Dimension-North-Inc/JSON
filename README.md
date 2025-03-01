# JSON Processing Package

This Swift package provides a lightweight, flexible system for processing JSON data, optimized for handling large structures efficiently. It consists of three core components:

- **`JSON.swift`**: A dual-tiered JSON representation with `verified` (strongly-typed) and `unverified` (raw) states, allowing selective parsing to minimize overhead.
- **`JSONPath.swift`**: A key path system for navigating JSON arrays and objects using a sequence of keys and offsets.
- **`JSONSearch.swift`**: A search utility for traversing JSON structures, executing actions on elements matching specified paths.

The package is designed for scenarios where fully deconstructing large JSON data into a structured form is costly. Instead, it enables developers to work with raw JSON data and selectively process only the parts they need, making it ideal for performance-sensitive applications.

## Features

- **Selective Parsing**: Use `JSON` to defer full parsing of large datasets until necessary, with `verified()` to convert raw data into structured `JSON.Value`.
- **Path-Based Navigation**: Define paths into JSON structures with `JSON.Path`, supporting both object keys and array offsets.
- **Flexible Search**: Use `JSON.Search` to perform targeted searches with multiple paths and associated actions, on both verified and unverified JSON.
- **Type Safety**: Leverage Swift’s strong typing for verified JSON values while retaining flexibility with unverified raw data.
- **Codable Support**: Seamlessly encode and decode JSON structures.

## Installation

Add this package to your Swift project via Swift Package Manager. In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/json-package.git", from: "1.0.0")
]
