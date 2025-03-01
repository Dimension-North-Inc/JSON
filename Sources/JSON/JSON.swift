//
//  JSON.swift
//  JSON
//
//  Created by Mark Onyschuk on 2/28/25.
//  Copyright 2025, Dimension North Inc. All Rights Reserved
//

import Foundation

/// A lightweight, flexible JSON representation designed for efficient handling of large JSON structures.
///
/// The `JSON` enum provides a two-tiered approach to JSON processing:
/// - `verified`: Strongly-typed `JSON.Value` cases for validated, structured data
/// - `unverified`: Raw, unprocessed representations for deferred parsing
///
/// This design minimizes the overhead of deconstructing large JSON structures by allowing selective
/// conversion to a structured enumeration only when needed, making it ideal for processing
/// large datasets transparently and efficiently.
public enum JSON {
    /// A strongly-typed representation of JSON values.
    public enum Value {
        /// Represents a JSON `null` value.
        case null
        
        /// Represents a JSON boolean value.
        case bool(Bool)
        
        /// Represents a JSON number, stored as a `Double`.
        case number(Double)
        
        /// Represents a JSON string.
        case string(String)
        
        /// Represents a JSON array, recursively containing `JSON.Value` elements.
        indirect case array([JSON.Value])
        
        /// Represents a JSON object, mapping strings to `JSON.Value` elements.
        indirect case object([String: JSON.Value])
    }

    /// A raw, unprocessed representation of JSON data, used for deferred parsing.
    public enum RawValue {
        /// An unverified JSON array containing raw `Any` elements.
        case array([Any])
        
        /// An unverified JSON object mapping strings to raw `Any` values.
        case object([String: Any])
    }
    
    /// A verified, strongly-typed JSON value.
    case verified(Value)
    
    /// An unverified, raw JSON value awaiting selective processing.
    case unverified(RawValue)
}

/// A protocol for types that can be represented as a `JSON.Value`.
///
/// Conforming types can be seamlessly converted to the `JSON.Value` enum,
/// enabling efficient integration with the `JSON` system.
public protocol JSONRepresentable {
    /// The JSON representation of the conforming instance.
    var jsonValue: JSON.Value { get }
}

// MARK: - JSONRepresentable Conformances

extension NSNull: JSONRepresentable {
    public var jsonValue: JSON.Value { .null }
}

extension NSString: JSONRepresentable {
    public var jsonValue: JSON.Value { .string(self as String) }
}

extension NSNumber: JSONRepresentable {
    public var jsonValue: JSON.Value {
        .number(doubleValue)
    }
}

extension Bool: JSONRepresentable {
    public var jsonValue: JSON.Value { .bool(self) }
}

extension Int: JSONRepresentable {
    public var jsonValue: JSON.Value { .number(Double(self)) }
}

extension Float: JSONRepresentable {
    public var jsonValue: JSON.Value { .number(Double(self)) }
}

extension Double: JSONRepresentable {
    public var jsonValue: JSON.Value { .number(self) }
}

extension String: JSONRepresentable {
    public var jsonValue: JSON.Value { .string(self) }
}

extension Substring: JSONRepresentable {
    public var jsonValue: JSON.Value { .string(String(self)) }
}

/// Errors thrown during JSON processing.
enum JSONError: Error {
    /// Indicates an invalid format for the provided type.
    case invalidFormat(Any.Type)
}

// MARK: - JSON Initialization and Access

extension JSON {
    /// Initializes a `JSON` instance from any value, selectively converting it to a structured form.
    ///
    /// - Parameter value: The value to convert, which can be `JSONRepresentable`, an array, or a dictionary.
    /// - Throws: `JSONError.invalidFormat` if the value cannot be represented as JSON.
    public init(_ value: Any) throws {
        if let value = value as? JSONRepresentable {
            self = .verified(value.jsonValue)
        } else if let value = value as? [Any] {
            self = .unverified(.array(value))
        } else if let value = value as? [String: Any] {
            self = .unverified(.object(value))
        } else {
            throw JSONError.invalidFormat(type(of: value))
        }
    }
    
    /// Initializes a `JSON` instance from raw data.
    ///
    /// - Parameter data: The JSON data to parse.
    /// - Throws: An error if the data cannot be deserialized or converted.
    public init(_ data: Data) throws {
        try self.init(try JSONSerialization.jsonObject(with: data, options: []))
    }
    
    /// A convenience property for a `null` JSON value.
    var null: Self {
        .verified(.null)
    }
    
    /// Accesses a value in a JSON object by key.
    ///
    /// - Parameter key: The key to look up in a JSON object.
    /// - Returns: The corresponding `JSON` value, or `null` if not found or not an object.
    /// - Throws: An error if unverified data cannot be converted.
    public subscript(key: String) -> JSON {
        get throws {
            switch self {
            case .unverified(.object(let dict)):
                if let value = dict[key] {
                    return try JSON(value)
                }
            case .verified(.object(let dict)):
                if let value = dict[key] {
                    return .verified(value)
                }
            default:
                break
            }
            return null
        }
    }
    
    /// Accesses an element in a JSON array by index.
    ///
    /// - Parameter index: The index to access in a JSON array.
    /// - Returns: The corresponding `JSON` value, or `null` if out of bounds or not an array.
    /// - Throws: An error if unverified data cannot be converted.
    public subscript(index: Int) -> JSON {
        get throws {
            switch self {
            case .unverified(.array(let array)):
                if array.indices.contains(index) {
                    return try JSON(array[index])
                }
            case .verified(.array(let array)):
                if array.indices.contains(index) {
                    return .verified(array[index])
                }
            default:
                break
            }
            return null
        }
    }
}

// MARK: - JSON Verification

extension JSON {
    /// Converts the `JSON` instance to a fully verified `JSON.Value`.
    ///
    /// This method processes unverified raw data into a structured `JSON.Value`,
    /// enabling full type safety at the cost of immediate processing.
    ///
    /// - Returns: A verified `JSON.Value`.
    /// - Throws: An error if the raw data cannot be converted.
    public func verified() throws -> JSON.Value {
        switch self {
        case let .verified(value):
            return value
        case let .unverified(.array(value)):
            return try JSON.Value(value)
        case let .unverified(.object(value)):
            return try JSON.Value(value)
        }
    }
}

// MARK: - Codable Support

extension JSON: Codable {
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .verified(let value):
            try value.encode(to: encoder)
        case .unverified(let raw):
            let value = try JSON.Value(raw)
            try value.encode(to: encoder)
        }
    }

    public init(from decoder: Decoder) throws {
        let value = try JSON.Value(from: decoder)
        self = .verified(value)
    }
}

// MARK: - JSON.Value Implementation

extension JSON.Value {
    /// Initializes a `JSON.Value` from any value, recursively processing arrays and objects.
    ///
    /// - Parameter value: The value to convert.
    /// - Throws: `JSONError.invalidFormat` if the value cannot be represented.
    init(_ value: Any) throws {
        if let value = value as? JSONRepresentable {
            self = value.jsonValue
        } else if let values = value as? [Any] {
            self = .array(try values.map(JSON.Value.init))
        } else if let object = value as? [String: Any] {
            self = .object(try object.mapValues(JSON.Value.init))
        } else {
            throw JSONError.invalidFormat(type(of: value))
        }
    }
    
    /// Accesses a value in a JSON object by key.
    public subscript(key: String) -> Self {
        get {
            if case .object(let object) = self, let value = object[key] {
                return value
            } else {
                return .null
            }
        }
    }
    
    /// Accesses an element in a JSON array by index.
    public subscript(index: Int) -> Self {
        get {
            if case .array(let array) = self, array.indices.contains(index) {
                return array[index]
            } else {
                return .null
            }
        }
    }
}

// MARK: - Hashable Support

extension JSON.Value: Hashable {
    /// Compares a `JSON.Value` with a `JSONRepresentable` instance for equality.
    public static func == (lhs: JSON.Value, rhs: some JSONRepresentable) -> Bool {
        switch lhs {
        case .null:
            return rhs is NSNull
        case .bool(let value):
            if let rhsBool = rhs as? Bool {
                return value == rhsBool
            }
        case .number(let value):
            if let rhsDouble = rhs as? Double {
                return value == rhsDouble
            } else if let rhsFloat = rhs as? Float {
                return value == Double(rhsFloat)
            } else if let rhsInt = rhs as? Int {
                return value == Double(rhsInt)
            }
        case .string(let value):
            if let rhsString = rhs as? String {
                return value == rhsString
            } else if let rhsSubstring = rhs as? Substring {
                return value == String(rhsSubstring)
            }
        case .array, .object:
            return false
        }
        return false
    }
    
    /// Compares a `JSONRepresentable` instance with a `JSON.Value` for equality.
    public static func == (lhs: some JSONRepresentable, rhs: JSON.Value) -> Bool {
        return rhs == lhs
    }
    
    /// Checks inequality between a `JSON.Value` and a `JSONRepresentable` instance.
    public static func != (lhs: JSON.Value, rhs: some JSONRepresentable) -> Bool {
        return !(lhs == rhs)
    }
    
    /// Checks inequality between a `JSONRepresentable` instance and a `JSON.Value`.
    public static func != (lhs: some JSONRepresentable, rhs: JSON.Value) -> Bool {
        return !(rhs == lhs)
    }
}

// MARK: - Comparable Support

extension JSON.Value: Comparable {
    /// Compares two `JSON.Value` instances for ordering.
    ///
    /// Defines a total ordering across JSON types:
    /// - `null` < `bool` < `number` < `string` < `array` < `object`
    /// - Within types, standard comparisons apply (e.g., lexicographical for strings).
    public static func < (lhs: JSON.Value, rhs: JSON.Value) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null):
            return false
        case (.bool(let lhsValue), .bool(let rhsValue)):
            return lhsValue == false && rhsValue == true
        case (.number(let lhsValue), .number(let rhsValue)):
            return lhsValue < rhsValue
        case (.string(let lhsValue), .string(let rhsValue)):
            return lhsValue < rhsValue
        case (.array(let lhsValues), .array(let rhsValues)):
            return lhsValues.lexicographicallyPrecedes(rhsValues)
        case (.object(let lhsDict), .object(let rhsDict)):
            return compareObjects(lhsDict, rhsDict)
        case (.null, _):
            return rhs != .null
        case (.bool, .number), (.bool, .string), (.bool, .array), (.bool, .object):
            return true
        case (.number, .string), (.number, .array), (.number, .object):
            return true
        case (.string, .array), (.string, .object):
            return true
        case (.array, .object):
            return true
        case (_, .null), (.number, .bool), (.string, .bool), (.string, .number),
            (.array, .bool), (.array, .number), (.array, .string),
            (.object, .bool), (.object, .number), (.object, .string), (.object, .array):
            return false
        }
    }
    
    /// Compares two JSON objects by sorting keys and values lexicographically.
    private static func compareObjects(_ lhs: [String: JSON.Value], _ rhs: [String: JSON.Value]) -> Bool {
        let lhsPairs = lhs.sorted(by: { $0.key < $1.key })
        let rhsPairs = rhs.sorted(by: { $0.key < $1.key })
        let lhsKeys = lhsPairs.map { $0.key }
        let rhsKeys = rhsPairs.map { $0.key }
        if lhsKeys != rhsKeys {
            return lhsKeys.lexicographicallyPrecedes(rhsKeys)
        }
        let lhsValues = lhsPairs.map { $0.value }
        let rhsValues = rhsPairs.map { $0.value }
        return lhsValues.lexicographicallyPrecedes(rhsValues)
    }
    
    /// Compares a `JSON.Value` with a `JSONRepresentable` instance for ordering.
    public static func < (lhs: JSON.Value, rhs: some JSONRepresentable) -> Bool {
        return lhs < rhs.jsonValue
    }
    
    /// Checks if a `JSON.Value` is less than or equal to a `JSONRepresentable` instance.
    public static func <= (lhs: JSON.Value, rhs: some JSONRepresentable) -> Bool {
        return lhs <= rhs.jsonValue
    }
    
    /// Checks if a `JSON.Value` is greater than a `JSONRepresentable` instance.
    public static func > (lhs: JSON.Value, rhs: some JSONRepresentable) -> Bool {
        return lhs > rhs.jsonValue
    }
    
    /// Checks if a `JSON.Value` is greater than or equal to a `JSONRepresentable` instance.
    public static func >= (lhs: JSON.Value, rhs: some JSONRepresentable) -> Bool {
        return lhs >= rhs.jsonValue
    }
    
    /// Compares a `JSONRepresentable` instance with a `JSON.Value` for ordering.
    public static func < (lhs: some JSONRepresentable, rhs: JSON.Value) -> Bool {
        return lhs.jsonValue < rhs
    }
    
    /// Checks if a `JSONRepresentable` instance is less than or equal to a `JSON.Value`.
    public static func <= (lhs: some JSONRepresentable, rhs: JSON.Value) -> Bool {
        return lhs.jsonValue <= rhs
    }
    
    /// Checks if a `JSONRepresentable` instance is greater than a `JSON.Value`.
    public static func > (lhs: some JSONRepresentable, rhs: JSON.Value) -> Bool {
        return lhs.jsonValue > rhs
    }
    
    /// Checks if a `JSONRepresentable` instance is greater than or equal to a `JSON.Value`.
    public static func >= (lhs: some JSONRepresentable, rhs: JSON.Value) -> Bool {
        return lhs.jsonValue >= rhs
    }
}

// MARK: - Codable for JSON.Value

extension JSON.Value: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let values):
            try container.encode(values)
        case .object(let dictionary):
            try container.encode(dictionary)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let numberValue = try? container.decode(Double.self) {
            self = .number(numberValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([JSON.Value].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: JSON.Value].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to decode JSON value"
                )
            )
        }
    }
}
