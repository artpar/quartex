import XCTest
@testable import AIAgent

class BasicTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func testLLMMessageBasics() {
        let message = LLMMessage(role: "user", content: "Hello")
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Hello")
    }
    
    func testLLMMessageJSON() throws {
        let message = LLMMessage(role: "assistant", content: "Hi!")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LLMMessage.self, from: data)
        
        XCTAssertEqual(message.role, decoded.role)
        XCTAssertEqual(message.content, decoded.content)
    }
    
    func testConversation() {
        var conversation = Conversation()
        XCTAssertTrue(conversation.messages.isEmpty)
        
        conversation.addUserMessage("Hello")
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.first?.role, "user")
        
        conversation.addAssistantMessage("Hi there!")
        XCTAssertEqual(conversation.messages.count, 2)
        XCTAssertEqual(conversation.messages.last?.role, "assistant")
    }
    
    func testLLMRequest() {
        let messages = [LLMMessage(role: "user", content: "Test")]
        let request = LLMRequest(messages: messages)
        
        XCTAssertEqual(request.model, "claude-3-sonnet-20240229")
        XCTAssertEqual(request.messages.count, 1)
        XCTAssertTrue(request.stream)
        XCTAssertEqual(request.max_tokens, 4000)
    }
    
    // MARK: - Utility Tests
    
    func testConstants() {
        XCTAssertFalse(Constants.appName.isEmpty)
        XCTAssertFalse(Constants.appVersion.isEmpty)
        XCTAssertGreaterThan(Constants.windowDefaultWidth, 0)
        XCTAssertGreaterThan(Constants.defaultMaxTokens, 0)
    }
    
    func testStringExtensions() {
        let text = "Hello World"
        XCTAssertTrue(text.isNotEmpty)
        
        let empty = ""
        XCTAssertFalse(empty.isNotEmpty)
        
        let withSpaces = "  test  "
        XCTAssertEqual(withSpaces.sanitized(), "test")
    }
    
    func testInputEvent() {
        let data = "test".data(using: .utf8)!
        let event = InputEvent(type: .text, content: data)
        
        XCTAssertEqual(event.type, .text)
        XCTAssertEqual(event.content, data)
        XCTAssertNotNil(event.id)
    }
    
    func testAIResponse() {
        let id = UUID()
        let response = AIResponse(content: "Test", conversationId: id)
        
        XCTAssertEqual(response.content, "Test")
        XCTAssertEqual(response.conversationId, id)
        XCTAssertFalse(response.isStreaming)
    }
    
    func testToolResult() {
        let success = ToolResult(success: true, output: "Done", error: nil)
        XCTAssertTrue(success.success)
        XCTAssertEqual(success.output, "Done")
        
        let failure = ToolResult(success: false, output: "", error: "Failed")
        XCTAssertFalse(failure.success)
        XCTAssertEqual(failure.error, "Failed")
    }
    
    // MARK: - Error Tests
    
    func testAIAgentErrors() {
        let noApiError = AIAgentError.noAPIKey
        XCTAssertNotNil(noApiError.errorDescription)
        
        let networkError = AIAgentError.networkError(URLError(.notConnectedToInternet))
        XCTAssertNotNil(networkError.errorDescription)
        
        let fileError = AIAgentError.fileOperationFailed("test error")
        XCTAssertTrue(fileError.errorDescription?.contains("test error") ?? false)
    }
}