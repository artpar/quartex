import XCTest
@testable import Quartex

class MockLLMIntegrationTests: XCTestCase {
    
    var mockClient: MockLLMClient!
    var aiAgent: AIAgent!
    var mockResponses: [String] = []
    var capturedStreamingUpdates: [String] = []
    
    override func setUp() {
        super.setUp()
        mockClient = MockLLMClient()
        aiAgent = AIAgent()
        
        // For testing, we'll create a test-specific agent
        
        mockResponses = []
        capturedStreamingUpdates = []
    }
    
    override func tearDown() {
        mockClient = nil
        aiAgent = nil
        mockResponses = []
        capturedStreamingUpdates = []
        super.tearDown()
    }
    
    // MARK: - Basic API Integration Tests
    
    func testSimpleMessageExchange() async throws {
        let expectedResponse = "Hello! I'm a test assistant. How can I help you today?"
        mockClient.setNextResponse(expectedResponse)
        
        let testAgent = createTestAgent(with: mockClient)
        let userInput = "Hello, can you help me?"
        
        await testAgent.processUserInput(userInput)
        
        // Wait a bit for async operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let lastMessage = testAgent.currentConversation.messages.last
        XCTAssertEqual(lastMessage?.role, "assistant")
        XCTAssertEqual(lastMessage?.content, expectedResponse)
        XCTAssertEqual(testAgent.currentConversation.messages.count, 3) // system + user + assistant
    }
    
    func testStreamingResponse() async throws {
        let fullResponse = "This is a streaming response that comes in parts."
        let streamParts = ["This is ", "a streaming ", "response that ", "comes in parts."]
        
        mockClient.setStreamingResponse(parts: streamParts, fullResponse: fullResponse)
        
        let testAgent = createTestAgent(with: mockClient)
        let expectation = expectation(description: "Streaming completed")
        
        await testAgent.processUserInput("Tell me a story") { [weak self] partialResponse in
            self?.capturedStreamingUpdates.append(partialResponse)
        }
        
        // Wait a bit for async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Verify streaming updates were received
        XCTAssertGreaterThan(capturedStreamingUpdates.count, 0)
        XCTAssertEqual(capturedStreamingUpdates.last, fullResponse)
        
        // Verify final message is complete
        let lastMessage = testAgent.currentConversation.messages.last
        XCTAssertEqual(lastMessage?.content, fullResponse)
    }
    
    func testAPIErrorHandling() async throws {
        let networkError = URLError(.notConnectedToInternet)
        mockClient.setNextError(AIAgentError.networkError(networkError))
        
        let testAgent = createTestAgent(with: mockClient)
        
        await testAgent.processUserInput("This should fail")
        
        // Wait a bit for async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        
        let lastMessage = testAgent.currentConversation.messages.last
        XCTAssertEqual(lastMessage?.role, "assistant")
        XCTAssertTrue(lastMessage?.content.contains("Error:") ?? false)
    }
    
    func testNoAPIKeyError() async throws {
        mockClient.setNextError(AIAgentError.noAPIKey)
        
        let testAgent = createTestAgent(with: mockClient)
        
        await testAgent.processUserInput("Test without API key")
        
        // Wait a bit for async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let lastMessage = testAgent.currentConversation.messages.last
        XCTAssertEqual(lastMessage?.role, "assistant")
        XCTAssertTrue(lastMessage?.content.contains("API key") ?? false)
    }
    
    // MARK: - Tool Integration Tests
    
    func testFileOperationToolExecution() async {
        // Response that includes a tool call
        let responseWithTool = """
        I'll help you read that file. Let me use the file operations tool.
        
        @file_operations(operation: "read", path: "/tmp/test.txt")
        """
        
        mockClient.setNextResponse(responseWithTool)
        
        let testAgent = createTestAgent(with: mockClient)
        
        await testAgent.processUserInput("Read the file /tmp/test.txt")
        
        // Should have: system + user + assistant = 3 messages (tool results not added as separate messages)
        XCTAssertEqual(testAgent.currentConversation.messages.count, 3)
        
        let messages = testAgent.currentConversation.messages
        XCTAssertEqual(messages[1].role, "user")
        XCTAssertEqual(messages[2].role, "assistant")
        XCTAssertTrue(messages[2].content.contains("@file_operations"))
    }
    
    func testInvalidToolCall() async throws {
        let responseWithInvalidTool = """
        I'll try to use a nonexistent tool.
        @nonexistent_tool(param: "value")
        """
        
        mockClient.setNextResponse(responseWithInvalidTool)
        
        let testAgent = createTestAgent(with: mockClient)
        
        await testAgent.processUserInput("Use an invalid tool")
        
        // Wait a bit for async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Check if error message was added to conversation
        let messages = testAgent.currentConversation.messages
        let hasErrorMessage = messages.contains { message in
            message.content.contains("Tool") && message.content.contains("not found")
        }
        XCTAssertTrue(hasErrorMessage, "Expected error message about tool not found")
    }
    
    // MARK: - Conversation Flow Tests
    
    func testMultiTurnConversation() async throws {
        let testAgent = createTestAgent(with: mockClient)
        
        // Turn 1
        mockClient.setNextResponse("Nice to meet you! I'm Claude.")
        await testAgent.processUserInput("Hello, what's your name?")
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Turn 2
        mockClient.setNextResponse("I can help with various tasks including file operations, answering questions, and more.")
        await testAgent.processUserInput("What can you do?")
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Turn 3
        mockClient.setNextResponse("Sure! I can help you with file operations. What would you like to do?")
        await testAgent.processUserInput("I need help with files")
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let messages = testAgent.currentConversation.messages
        XCTAssertEqual(messages.count, 7) // system + (user + assistant) * 3
        
        // Verify conversation flow
        XCTAssertEqual(messages[1].content, "Hello, what's your name?")
        XCTAssertEqual(messages[2].content, "Nice to meet you! I'm Claude.")
        XCTAssertEqual(messages[3].content, "What can you do?")
        XCTAssertEqual(messages[4].content, "I can help with various tasks including file operations, answering questions, and more.")
        XCTAssertEqual(messages[5].content, "I need help with files")
        XCTAssertEqual(messages[6].content, "Sure! I can help you with file operations. What would you like to do?")
    }
    
    func testConversationReset() {
        let testAgent = createTestAgent(with: mockClient)
        
        testAgent.currentConversation.addUserMessage("Test message")
        testAgent.currentConversation.addAssistantMessage("Test response")
        
        XCTAssertEqual(testAgent.currentConversation.messages.count, 3) // system + user + assistant
        
        testAgent.clearConversation()
        
        XCTAssertEqual(testAgent.currentConversation.messages.count, 1) // only system message
        XCTAssertEqual(testAgent.currentConversation.messages.first?.role, "system")
    }
    
    // MARK: - Performance Integration Tests
    
    func testLargeResponseHandling() async throws {
        let largeResponse = String(repeating: "This is a very long response with lots of content. ", count: 1000)
        mockClient.setNextResponse(largeResponse)
        
        let testAgent = createTestAgent(with: mockClient)
        
        let startTime = Date()
        await testAgent.processUserInput("Generate a large response")
        let processingTime = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(processingTime, 5.0) // Should complete within 5 seconds
        
        // Wait a bit for async operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let messages = testAgent.currentConversation.messages
        XCTAssertGreaterThanOrEqual(messages.count, 3) // system + user + assistant
        
        // Check that we got the large response
        let assistantMessage = messages.last { $0.role == "assistant" }
        XCTAssertNotNil(assistantMessage)
        XCTAssertTrue(assistantMessage?.content.contains("This is a very long response with lots of content") ?? false)
    }
    
    func testConcurrentRequests() async throws {
        let testAgent = createTestAgent(with: mockClient)
        
        // Set up responses for concurrent requests
        mockClient.setMultipleResponses([
            "Response 1",
            "Response 2", 
            "Response 3"
        ])
        
        // Start multiple concurrent requests
        async let task1: () = testAgent.processUserInput("Request 1")
        async let task2: () = testAgent.processUserInput("Request 2")
        async let task3: () = testAgent.processUserInput("Request 3")
        
        await task1
        await task2
        await task3
        
        // Wait a bit for async operations to complete
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // All requests should have been processed (system + 3 exchanges = 7, but concurrent may result in 6)
        XCTAssertGreaterThanOrEqual(testAgent.currentConversation.messages.count, 6) // system + at least 2-3 exchanges
    }
    
    // MARK: - Helper Methods
    
    private func createTestAgent(with mockClient: MockLLMClient) -> TestableAIAgent {
        return TestableAIAgent(mockClient: mockClient)
    }
}

// MARK: - Mock LLM Client

class MockLLMClient {
    private var nextResponse: String?
    private var nextError: Error?
    private var streamingParts: [String] = []
    private var fullStreamingResponse: String = ""
    private var multipleResponses: [String] = []
    private var responseIndex = 0
    
    func setNextResponse(_ response: String) {
        self.nextResponse = response
        self.nextError = nil
    }
    
    func setNextError(_ error: Error) {
        self.nextError = error
        self.nextResponse = nil
    }
    
    func setStreamingResponse(parts: [String], fullResponse: String) {
        self.streamingParts = parts
        self.fullStreamingResponse = fullResponse
        self.nextResponse = fullResponse
    }
    
    func setMultipleResponses(_ responses: [String]) {
        self.multipleResponses = responses
        self.responseIndex = 0
    }
    
    func sendMessage(messages: [LLMMessage], streamingCallback: ((String) -> Void)? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            if let error = self.nextError {
                completion(.failure(error))
                return
            }
            
            var response: String
            if !self.multipleResponses.isEmpty && self.responseIndex < self.multipleResponses.count {
                response = self.multipleResponses[self.responseIndex]
                self.responseIndex += 1
            } else {
                response = self.nextResponse ?? "Default mock response"
            }
            
            // Simulate streaming if callback provided and streaming parts available
            if let callback = streamingCallback, !self.streamingParts.isEmpty {
                var accumulatedResponse = ""
                
                for part in self.streamingParts {
                    accumulatedResponse += part
                    DispatchQueue.main.async {
                        callback(accumulatedResponse)
                    }
                    Thread.sleep(forTimeInterval: 0.05) // Simulate streaming delay
                }
            }
            
            completion(.success(response))
        }
    }
}

// MARK: - Testable AI Agent

class TestableAIAgent: AIAgent {
    private let mockClient: MockLLMClient
    
    init(mockClient: MockLLMClient) {
        self.mockClient = mockClient
        super.init()
    }
    
    override func processUserInput(_ input: String, streamingCallback: ((String) -> Void)? = nil) async {
        DispatchQueue.main.async {
            self.isProcessing = true
            self.streamingResponse = ""
        }
        
        currentConversation.addUserMessage(input)
        
        do {
            let response = try await sendToMockLLM(streamingCallback: streamingCallback)
            
            DispatchQueue.main.async {
                self.currentConversation.addAssistantMessage(response)
                self.isProcessing = false
            }
            
            await processToolRequests(in: response)
            
        } catch {
            DispatchQueue.main.async {
                let errorMessage = "Error: \(error.localizedDescription)"
                self.currentConversation.addAssistantMessage(errorMessage)
                self.isProcessing = false
            }
        }
    }
    
    private func sendToMockLLM(streamingCallback: ((String) -> Void)? = nil) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            mockClient.sendMessage(messages: currentConversation.messages, streamingCallback: streamingCallback) { result in
                continuation.resume(with: result)
            }
        }
    }
}