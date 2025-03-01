import Testing
import Foundation

@testable import JSON

@Test("JSON creation from raw data")
func testJSONCreation() throws {
    let rawData: [String: Any] = [
        "name": "Mark",
        "age": 30,
        "active": true,
        "nested": ["value": 42]
    ]
    let json = try JSON(rawData)
    
    var verified: JSON.Value?
    #expect(throws: Never.self) {
        verified = try json.verified()
    }
    #expect(verified != .null, "Verified JSON should not be null")
    
    switch json {
    case .unverified(.object(let dict)):
        #expect(dict["name"] as? String == "Mark", "Name should match")
        #expect(dict["age"] as? Int == 30, "Age should match")
        #expect(dict["active"] as? Bool == true, "Active should match")
        #expect(dict["nested"] is [String: Any], "Nested should be a dictionary")
        if let nested = dict["nested"] as? [String: Any] {
            #expect(nested["value"] as? Int == 42, "Nested value should match")
        }
    case .unverified(.array):
        #expect(Bool(false), "Expected an unverified object, got an array")
    case .verified:
        #expect(Bool(false), "Expected an unverified object, got a verified value")
    }
}

@Test("Fast instantiation from JSONSerialization")
func testFastInstantiation() throws {
    let jsonString = """
    {
        "id": 123,
        "data": {"value": "test", "count": 42},
        "list": [1, 2, 3]
    }
    """
    let data = jsonString.data(using: .utf8)!
    let raw = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let json = try JSON(raw)
    
    switch json {
    case .unverified(.object(let dict)):
        #expect(dict["id"] as? Int == 123, "ID should match")
        #expect(dict["data"] is [String: Any], "Data should be a dictionary")
        #expect(dict["list"] is [Any], "List should be an array")
    default:
        #expect(Bool(false), "Expected unverified object from raw JSON")
    }
}

@Test("JSON.Search on unverified JSON with Path")
func testSearchUnverified() throws {
    let rawData: [String: Any] = [
        "users": [
            ["name": "Mark", "age": 30],
            ["name": "Jane", "age": 25]
        ],
        "meta": ["count": 2]
    ]
    let json = try JSON(rawData)
    
    var names: [JSON.Value] = []
    try json.on("users.0.name", "users.1.name") { json in
        names.append(try json.verified())
    }.run()
    
    print("FOO")
    
    #expect(names.count == 2, "Should find two names")
    #expect(names[0] == .string("Mark"), "First name should be Mark")
    #expect(names[1] == .string("Jane"), "Second name should be Jane")
}

@Test("Lazy verification with JSON.Search")
func testLazyVerification() throws {
    let rawData: [String: Any] = [
        "users": [
            ["name": "Mark", "age": 30],
            ["name": "Jane", "age": 25]
        ]
    ]
    let json = try JSON(rawData)
    
    var ages: [JSON.Value] = []
    try json.on("users.0.age", "users.1.age") { json in
        let verified = try json.verified()
        ages.append(verified)
    }.run()
    
    #expect(ages.count == 2, "Should find two ages")
    #expect(ages[0] == .number(30.0), "First age should be 30")
    #expect(ages[1] == .number(25.0), "Second age should be 25")
}

@Test("Scalability with arbitrary JSON structures")
func testScalability() throws {
    // Simulate a larger, arbitrary JSON structure
    var rawData: [String: Any] = [:]
    var users: [[String: Any]] = []
    for i in 0..<100 {  // 100 users as a small-scale test
        users.append([
            "id": i,
            "name": "User\(i)",
            "scores": [Double.random(in: 0...100), Double.random(in: 0...100)]
        ])
    }
    rawData["users"] = users
    
    let json = try JSON(rawData)
    
    var nameCount = 0
    try json.on("users.50.name") { json in
        nameCount += 1
        let verified = try json.verified()
        #expect(verified == .string("User50"), "Should find User50")
    }.run()
    
    #expect(nameCount == 1, "Should find exactly one matching name")
}
