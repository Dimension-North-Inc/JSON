//
//  JSONSearch.swift
//  JSON
//
//  Created by Mark Onyschuk on 2/28/25.
//  Copyright 2025, Dimension North Inc. All Rights Reserved
//

import Foundation

extension JSON {
    /// A utility for searching JSON data by key paths, supporting actions on matched elements.
    ///
    /// `Search` allows traversal of both verified (`JSON.Value`) and unverified (`JSON`) structures,
    /// associating multiple `JSON.Path` instances with actions to perform when those paths match.
    /// This enables efficient, targeted processing of JSON data, whether fully parsed or still raw.
    public final class Search<T> {
        /// The root data being searched.
        private let root: Root
        
        /// A list of path-action pairs defining the search criteria and operations.
        private var pathActions: [(paths: [JSON.Path], action: (T) throws -> Void)]
        
        /// The type of data being searched, either `JSON` or `JSON.Value`.
        private enum Root {
            /// A case for searching unverified or mixed JSON data.
            case json(JSON)
            
            /// A case for searching fully verified JSON values.
            case value(JSON.Value)
        }
        
        /// Initializes a search for unverified or mixed JSON data.
        ///
        /// - Parameter json: The `JSON` instance to search.
        init(json: JSON) where T == JSON {
            self.root = .json(json)
            self.pathActions = []
        }
        
        /// Initializes a search for verified JSON values.
        ///
        /// - Parameter value: The `JSON.Value` instance to search.
        init(value: JSON.Value) where T == JSON.Value {
            self.root = .value(value)
            self.pathActions = []
        }
        
        /// Registers an action to perform when any of the specified paths match.
        ///
        /// - Parameters:
        ///   - paths: A variadic list of `JSON.Path` instances to match.
        ///   - perform: The action to execute on matching elements.
        /// - Returns: The `Search` instance for chaining.
        @discardableResult
        public func on(_ paths: JSON.Path..., perform: @escaping (T) throws -> Void) -> Self {
            pathActions.append((paths: paths, action: perform))
            return self
        }
        
        /// Registers an action to perform when any of the specified paths match.
        ///
        /// - Parameters:
        ///   - paths: An array of `JSON.Path` instances to match.
        ///   - perform: The action to execute on matching elements.
        /// - Returns: The `Search` instance for chaining.
        @discardableResult
        public func on(_ paths: [JSON.Path], perform: @escaping (T) throws -> Void) -> Self {
            pathActions.append((paths: paths, action: perform))
            return self
        }
        
        /// Executes the search on unverified or mixed JSON data.
        ///
        /// Traverses the JSON structure, invoking registered actions when paths match.
        ///
        /// - Returns: The `Search` instance for chaining.
        /// - Throws: Errors from the action closures or JSON conversion.
        @discardableResult
        public func run() throws -> Self where T == JSON {
            guard case .json(let json) = root else { fatalError("Type mismatch") }
            try search(json: json, currentPath: .root)
            return self
        }
        
        /// Executes the search on verified JSON values.
        ///
        /// Traverses the JSON structure, invoking registered actions when paths match.
        ///
        /// - Returns: The `Search` instance for chaining.
        /// - Throws: Errors from the action closures.
        @discardableResult
        public func run() throws -> Self where T == JSON.Value {
            guard case .value(let value) = root else { fatalError("Type mismatch") }
            try search(value: value, currentPath: .root)
            return self
        }
        
        /// Recursively searches unverified or mixed JSON data.
        ///
        /// - Parameters:
        ///   - json: The current `JSON` instance being searched.
        ///   - currentPath: The current path in the traversal.
        /// - Throws: Errors from actions or JSON conversion.
        private func search(json: JSON, currentPath: JSON.Path) throws where T == JSON {
            for (paths, action) in pathActions {
                for path in paths {
                    if currentPath.endsWith(path) {
                        try action(json)
                        break
                    }
                }
            }
            
            switch json {
            case .verified(let value):
                switch value {
                case .array(let values):
                    for (index, element) in values.enumerated() {
                        var newPath = currentPath
                        newPath.push(.offset(index))
                        try search(json: .verified(element), currentPath: newPath)
                    }
                case .object(let dict):
                    for (key, value) in dict {
                        var newPath = currentPath
                        newPath.push(.key(key))
                        try search(json: .verified(value), currentPath: newPath)
                    }
                case .null, .bool, .number, .string:
                    break
                }
            case .unverified(let raw):
                switch raw {
                case .array(let values):
                    for (index, element) in values.enumerated() {
                        var newPath = currentPath
                        newPath.push(.offset(index))
                        try search(json: try JSON(element), currentPath: newPath)
                    }
                case .object(let dict):
                    for (key, value) in dict {
                        var newPath = currentPath
                        newPath.push(.key(key))
                        try search(json: try JSON(value), currentPath: newPath)
                    }
                }
            }
        }
        
        /// Recursively searches verified JSON values.
        ///
        /// - Parameters:
        ///   - value: The current `JSON.Value` being searched.
        ///   - currentPath: The current path in the traversal.
        /// - Throws: Errors from actions.
        private func search(value: JSON.Value, currentPath: JSON.Path) throws where T == JSON.Value {
            for (paths, action) in pathActions {
                for path in paths {
                    if currentPath.endsWith(path) {
                        try action(value)
                        break
                    }
                }
            }
            
            switch value {
            case .array(let values):
                for (index, element) in values.enumerated() {
                    var newPath = currentPath
                    newPath.push(.offset(index))
                    try search(value: element, currentPath: newPath)
                }
            case .object(let dict):
                for (key, value) in dict {
                    var newPath = currentPath
                    newPath.push(.key(key))
                    try search(value: value, currentPath: newPath)
                }
            case .null, .bool, .number, .string:
                break
            }
        }
    }
}

// MARK: - Convenience Extensions

extension JSON {
    /// Creates and configures a search for this JSON instance with variadic paths.
    ///
    /// - Parameters:
    ///   - paths: A variadic list of `JSON.Path` instances to match.
    ///   - perform: The action to execute on matching elements.
    /// - Returns: A configured `Search<JSON>` instance.
    /// - Throws: Errors from the action closure.
    public func on(_ paths: JSON.Path..., perform: @escaping (JSON) throws -> Void) rethrows -> Search<JSON> {
        return Search<JSON>(json: self)
            .on(paths, perform: perform)
    }
}

extension JSON.Value {
    /// Creates and configures a search for this JSON value with variadic paths.
    ///
    /// - Parameters:
    ///   - paths: A variadic list of `JSON.Path` instances to match.
    ///   - perform: The action to execute on matching elements.
    /// - Returns: A configured `Search<JSON.Value>` instance.
    /// - Throws: Errors from the action closure.
    public func on(_ paths: JSON.Path..., perform: @escaping (JSON.Value) throws -> Void) rethrows -> JSON.Search<JSON.Value> {
        return JSON.Search<JSON.Value>(value: self)
            .on(paths, perform: perform)
    }
}
