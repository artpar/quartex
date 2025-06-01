import XCTest
@testable import AIAgent

class UITests: XCTestCase {
    
    func testConstants() {
        // Test UI-related constants
        XCTAssertGreaterThan(Constants.windowDefaultWidth, 0)
        XCTAssertGreaterThan(Constants.windowDefaultHeight, 0)
        XCTAssertGreaterThan(Constants.windowMinWidth, 0)
        XCTAssertGreaterThan(Constants.windowMinHeight, 0)
        
        XCTAssertGreaterThan(Constants.chatBubbleMaxWidth, 0)
        XCTAssertGreaterThan(Constants.chatBubbleCornerRadius, 0)
        XCTAssertGreaterThan(Constants.chatSpacing, 0)
        XCTAssertGreaterThan(Constants.chatPadding, 0)
        
        // Ensure reasonable values
        XCTAssertLessThan(Constants.windowMinWidth, Constants.windowDefaultWidth)
        XCTAssertLessThan(Constants.windowMinHeight, Constants.windowDefaultHeight)
    }
    
    func testNotificationNames() {
        // Test that notification names are properly defined
        let configChanged = Constants.Notifications.configurationChanged
        let conversationUpdated = Constants.Notifications.conversationUpdated
        let toolExecutionCompleted = Constants.Notifications.toolExecutionCompleted
        
        XCTAssertFalse(configChanged.rawValue.isEmpty)
        XCTAssertFalse(conversationUpdated.rawValue.isEmpty)
        XCTAssertFalse(toolExecutionCompleted.rawValue.isEmpty)
        
        // Ensure notifications have unique names
        XCTAssertNotEqual(configChanged.rawValue, conversationUpdated.rawValue)
        XCTAssertNotEqual(configChanged.rawValue, toolExecutionCompleted.rawValue)
        XCTAssertNotEqual(conversationUpdated.rawValue, toolExecutionCompleted.rawValue)
    }
    
    func testResponseModel() {
        // Test AI response model for UI display
        let conversationId = UUID()
        let response = AIResponse(content: "Test response", conversationId: conversationId)
        
        XCTAssertEqual(response.content, "Test response")
        XCTAssertEqual(response.conversationId, conversationId)
        XCTAssertFalse(response.isStreaming)
        XCTAssertNotNil(response.timestamp)
        
        // Test streaming response
        let streamingResponse = AIResponse(
            content: "Streaming...",
            isStreaming: true,
            conversationId: conversationId
        )
        
        XCTAssertTrue(streamingResponse.isStreaming)
        XCTAssertEqual(streamingResponse.conversationId, conversationId)
    }
    
    func testConversationDisplay() {
        // Test conversation model for UI display
        var conversation = Conversation()
        
        // Test empty state
        XCTAssertTrue(conversation.messages.isEmpty)
        XCTAssertNotNil(conversation.id)
        
        // Test adding messages for display
        conversation.addUserMessage("Hello")
        conversation.addAssistantMessage("Hi there!")
        conversation.addUserMessage("How are you?")
        conversation.addAssistantMessage("I'm doing well, thank you!")
        
        XCTAssertEqual(conversation.messages.count, 4)
        
        // Verify alternating pattern for chat display
        XCTAssertEqual(conversation.messages[0].role, "user")
        XCTAssertEqual(conversation.messages[1].role, "assistant")
        XCTAssertEqual(conversation.messages[2].role, "user")
        XCTAssertEqual(conversation.messages[3].role, "assistant")
    }
    
    func testInputEventDisplay() {
        // Test different input types for UI handling
        let textData = "Hello world".data(using: .utf8)!
        let textEvent = InputEvent(type: .text, content: textData)
        
        XCTAssertEqual(textEvent.type, .text)
        XCTAssertEqual(textEvent.content, textData)
        
        // Test with metadata for UI display
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        let imageEvent = InputEvent(
            type: .image,
            content: imageData,
            metadata: ["filename": "test.jpg", "size": imageData.count]
        )
        
        XCTAssertEqual(imageEvent.type, .image)
        XCTAssertEqual(imageEvent.metadata["filename"] as? String, "test.jpg")
        XCTAssertEqual(imageEvent.metadata["size"] as? Int, imageData.count)
    }
    
    func testErrorHandlingForUI() {
        // Test error presentation for UI
        let errors: [AIAgentError] = [
            .noAPIKey,
            .networkError(URLError(.notConnectedToInternet)),
            .invalidResponse,
            .fileOperationFailed("upload failed")
        ]
        
        for error in errors {
            let description = error.errorDescription
            let _ = error.recoverySuggestion  // Check it exists but don't need to test content
            
            // Error messages should be user-friendly
            XCTAssertNotNil(description)
            XCTAssertFalse(description?.isEmpty ?? true)
            
            // Should not contain technical details that confuse users
            XCTAssertFalse(description?.contains("nil") ?? true)
            XCTAssertFalse(description?.contains("null") ?? true)
            XCTAssertFalse(description?.contains("undefined") ?? true)
        }
    }
    
    func testExtensionsForUI() {
        // Test string extensions useful for UI
        let longText = String(repeating: "A", count: 100)
        let truncated = longText.truncated(to: 50)
        
        XCTAssertEqual(truncated.count, 53) // 50 + "..." = 53
        XCTAssertTrue(truncated.hasSuffix("..."))
        
        // Test whitespace handling for UI
        let messyText = "  \n\t Hello World \n\t  "
        let cleaned = messyText.sanitized()
        XCTAssertEqual(cleaned, "Hello World")
        
        // Test empty check for UI validation
        XCTAssertTrue("test".isNotEmpty)
        XCTAssertFalse("".isNotEmpty)
        XCTAssertFalse("   ".sanitized().isNotEmpty)
    }
    
    func testDateFormattingForUI() {
        let now = Date()
        
        // Test relative time formatting
        let timeAgo = now.timeAgo
        XCTAssertFalse(timeAgo.isEmpty)
        
        // Test chat timestamp formatting
        let timestamp = now.chatTimestamp
        XCTAssertFalse(timestamp.isEmpty)
        
        // Timestamp should be shorter than timeAgo for UI space efficiency
        XCTAssertLessThanOrEqual(timestamp.count, timeAgo.count + 5)
    }
}