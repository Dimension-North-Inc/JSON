//
//  JSONPath.swift
//  JSON
//
//  Created by Mark Onyschuk on 2/26/25.
//  Copyright 2025, Dimension North Inc. All Rights Reserved
//

import Foundation

extension JSON {
    /// A type representing a path into a JSON structure, used to access nested elements in arrays and objects.
    ///
    /// `Path` models a sequence of components—either keys (for objects) or offsets (for arrays)—allowing
    /// precise navigation through a `JSON` structure. It supports flexible initialization and manipulation,
    /// making it a key tool for querying and traversing JSON data efficiently.
    public struct Path: Hashable, Sendable {
        /// The sequence of components defining the path.
        var elements: [JSON.Path.Component]
        
        /// Initializes a path with an array of components.
        ///
        /// - Parameter elements: The components defining the path.
        public init(_ elements: [JSON.Path.Component]) {
            self.elements = elements
        }
        
        /// Initializes a path from a collection of components.
        ///
        /// - Parameter elements: A collection of components to convert into an array.
        public init(_ elements: some Collection<JSON.Path.Component>) {
            self.elements = Array(elements)
        }
        
        /// A constant representing the root of a JSON structure (an empty path).
        public static let root = JSON.Path([])

        /// A component of a JSON path, representing either a key in an object or an offset in an array.
        public enum Component: Hashable, Sendable {
            /// A key for accessing a value in a JSON object.
            case key(String)
            
            /// An offset for accessing an element in a JSON array.
            case offset(Int)
        }
        
        /// Appends a component to the end of the path.
        ///
        /// - Parameter component: The component to append.
        mutating func push(_ component: Component) {
            elements.append(component)
        }
        
        /// Removes the last component from the path.
        mutating func pop() {
            elements.removeLast()
        }
        
        /// Checks if the path ends with the specified target path.
        ///
        /// - Parameter target: The path to check against the suffix of this path.
        /// - Returns: `true` if this path ends with the target path, `false` otherwise.
        public func endsWith(_ target: JSON.Path) -> Bool {
            guard !target.elements.isEmpty else { return false }
            guard elements.count >= target.elements.count else { return false }
            let suffixLength = target.elements.count
            return elements.suffix(suffixLength) == target.elements
        }
    }
}

// MARK: - Collection Conformance

/// Extends `JSON.Path` to conform to `RandomAccessCollection`, enabling indexed access to components.
extension JSON.Path: RandomAccessCollection {
    /// Accesses a component at the specified position.
    public subscript(position: Int) -> Component {
        elements[position]
    }
    
    /// The index after the last component.
    public var endIndex: Int { elements.endIndex }
    
    /// The index of the first component.
    public var startIndex: Int { elements.startIndex }
}

// MARK: - Literal Conformances

/// Extends `JSON.Path` to support initialization from string and integer literals.
extension JSON.Path: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    /// Initializes a path from a string literal, parsing it into components.
    ///
    /// The string is split by `.` into components:
    /// - Numeric strings (e.g., "0") become `.offset` components.
    /// - Non-numeric strings (e.g., "key") become `.key` components.
    /// - Empty segments are ignored.
    ///
    /// Example: `"users.0.name"` becomes `[.key("users"), .offset(0), .key("name")]`.
    public init(stringLiteral value: String) {
        self.elements = value.components(separatedBy: ".").compactMap { elt in
            if elt.isEmpty { return nil }
            if !elt.contains(where: { $0.isLetter }), let offset = Int(elt) {
                return .offset(offset)
            } else {
                return .key(elt)
            }
        }
    }
    
    /// Initializes a path from an integer literal, creating a single-offset path.
    ///
    /// Example: `0` becomes `[.offset(0)]`.
    public init(integerLiteral value: IntegerLiteralType) {
        self.elements = [.offset(value)]
    }
}

// MARK: - String Representations

/// Extends `JSON.Path` to provide human-readable string representations.
extension JSON.Path: CustomStringConvertible, CustomDebugStringConvertible {
    /// A string representation of the path, with components joined by dots.
    ///
    /// Example: `[.key("users"), .offset(0)]` becomes `"users.0"`.
    public var description: String {
        elements.map(\.description).joined(separator: ".")
    }
    
    /// A debug string representation, matching the standard description.
    public var debugDescription: String {
        description
    }
}

/// Extends `JSON.Path` to support initialization from an array literal of components.
extension JSON.Path: ExpressibleByArrayLiteral {
    /// Initializes a path from an array literal of components.
    ///
    /// Example: `[.key("users"), .offset(0)]` creates a path directly.
    public init(arrayLiteral elements: Component...) {
        self.elements = elements
    }
}

// MARK: - Component String Representations

/// Extends `JSON.Path.Component` to provide human-readable string representations.
extension JSON.Path.Component: CustomStringConvertible, CustomDebugStringConvertible {
    /// A string representation of the component.
    ///
    /// - `.key("name")` becomes `"name"`.
    /// - `.offset(0)` becomes `"0"`.
    public var description: String {
        switch self {
        case .key(let value): return value
        case .offset(let value): return value.description
        }
    }
    
    /// A debug string representation, matching the standard description.
    public var debugDescription: String {
        description
    }
}

/// Extends `JSON.Path.Component` to support initialization from string and integer literals.
extension JSON.Path.Component: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    /// Initializes a component from a string literal, treating it as a key.
    ///
    /// Example: `"name"` becomes `.key("name")`.
    public init(stringLiteral value: String) {
        self = .key(value)
    }
    
    /// Initializes a component from an integer literal, treating it as an offset.
    ///
    /// Example: `0` becomes `.offset(0)`.
    public init(integerLiteral value: Int) {
        self = .offset(value)
    }
}
