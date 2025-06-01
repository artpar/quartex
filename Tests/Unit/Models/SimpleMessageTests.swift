import XCTest
import Foundation
@testable import Quartex

// Simple standalone tests that don't depend on complex framework
class SimpleMessageTests: XCTestCase {
    
    // MARK: - Basic LLMMessage Tests
    
    func testLLMMessageCreation() {
        // Test the basic Message struct from our Models
        let message = LLMMessage(role: "user", content: "Hello")
        
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Hello")
    }
    
    func testLLMMessageSerialization() throws {
        let message = LLMMessage(role: "assistant", content: "Hi there!")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(LLMMessage.self, from: data)
        
        XCTAssertEqual(message.role, decodedMessage.role)
        XCTAssertEqual(message.content, decodedMessage.content)
    }
    
    func testConversationBasics() {
        var conversation = Conversation()
        
        XCTAssertTrue(conversation.messages.isEmpty)
        XCTAssertNotNil(conversation.id)
        
        conversation.addUserMessage("Hello")
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.first?.role, "user")
        XCTAssertEqual(conversation.messages.first?.content, "Hello")
        
        conversation.addAssistantMessage("Hi there!")
        XCTAssertEqual(conversation.messages.count, 2)
        XCTAssertEqual(conversation.messages.last?.role, "assistant")
        XCTAssertEqual(conversation.messages.last?.content, "Hi there!")
    }
    
    func testLLMRequestDefaults() {
        let messages = [LLMMessage(role: "user", content: "Test")]
        let request = LLMRequest(messages: messages)
        
        XCTAssertEqual(request.model, "claude-3-sonnet-20240229")
        XCTAssertEqual(request.messages.count, 1)
        XCTAssertTrue(request.stream)
        XCTAssertEqual(request.max_tokens, 4000)
    }
    
    func testToolResult() {
        let successResult = ToolResult(success: true, output: "Success", error: nil)
        XCTAssertTrue(successResult.success)
        XCTAssertEqual(successResult.output, "Success")
        XCTAssertNil(successResult.error)
        
        let failureResult = ToolResult(success: false, output: "", error: "Failed")
        XCTAssertFalse(failureResult.success)
        XCTAssertEqual(failureResult.error, "Failed")
    }
    
    func testInputEventBasics() {
        let testData = "Hello".data(using: .utf8)!
        let event = InputEvent(type: .text, content: testData)
        
        XCTAssertNotNil(event.id)
        XCTAssertEqual(event.type, .text)
        XCTAssertEqual(event.content, testData)
        XCTAssertNotNil(event.timestamp)
    }
    
    func testAIResponse() {
        let conversationId = UUID()
        let response = AIResponse(content: "Test response", conversationId: conversationId)
        
        XCTAssertEqual(response.content, "Test response")
        XCTAssertFalse(response.isStreaming)
        XCTAssertEqual(response.conversationId, conversationId)
        XCTAssertNotNil(response.timestamp)
    }
}