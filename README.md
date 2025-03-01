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
```

Then, include it in your target:

```swift
.target(name: "YourTarget", dependencies: ["JSON"])
```

## Usage Examples

Here are a few examples demonstrating the package’s intended usage.

### 1. Selective JSON Parsing

Parse a JSON string and access parts of it without fully converting the entire structure:

```swift
import JSON

let jsonData = """
{
    "users": [
        {"name": "Alice", "age": 30},
        {"name": "Bob", "age": 25}
    ],
    "metadata": {"version": 1}
}
""".data(using: .utf8)!

do {
    let json = try JSON(jsonData)
    
    // Access a specific user without parsing the whole structure
    let firstUser = try json["users"][0]
    print(try firstUser["name"].verified()) // Outputs: string("Alice")
    
    // Verify the entire structure only when needed
    let verified = try json.verified()
    print(verified["users"][1]["age"]) // Outputs: number(25.0)
} catch {
    print("Error: \(error)")
}
```

### 2. Defining and Using JSON Paths

Create paths to navigate JSON structures and check their properties:

```swift
import JSON

let path = JSON.Path("users.0.name") // [key("users"), offset(0), key("name")]
print(path.description) // "users.0.name"

let anotherPath = JSON.Path([.key("metadata"), .key("version")])
print(anotherPath.endsWith(JSON.Path("version"))) // true
```

### 3. Searching JSON with Multiple Paths

Search a JSON structure for specific paths and perform actions on matches:

```swift
import JSON

let jsonData = """
{
    "users": [
        {"name": "Alice", "details": {"active": true}},
        {"name": "Bob", "details": {"active": false}}
    ]
}
""".data(using: .utf8)!

do {
    let json = try JSON(jsonData)
    
    try json.on(
        "users.0.name",
        "users.1.details.active"
    ) { value in
        print("Matched: \(try value.verified())")
    }.run()
    
    // Outputs:
    // Matched: string("Alice")
    // Matched: bool(false)
} catch {
    print("Error: \(error)")
}
```

### 4. Working with Verified JSON Values

Search within a fully verified JSON structure for fine-grained control:

```swift
import JSON

let value = JSON.Value.object([
    "settings": .object([
        "theme": .string("dark"),
        "volume": .number(75.0)
    ])
])

do {
    try value.on("settings.theme") { val in
        print("Theme: \(val)") // Outputs: Theme: string("dark")
    }.run()
} catch {
    print("Error: \(error)")
}
```

## Design Philosophy

- **Efficiency**: By distinguishing between `verified` and `unverified` JSON, the package avoids unnecessary parsing of large datasets until explicitly requested.
- **Flexibility**: `JSON.Path` and `JSON.Search` provide a declarative way to query and process JSON, supporting both simple and complex use cases.
- **Transparency**: Developers control when and where data is fully processed, making performance trade-offs explicit.

## License

This package is licensed under the MIT License. See the `LICENSE` file for details.
