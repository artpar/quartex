import XCTest
@testable import AIAgent

class PerformanceTests: XCTestCase {
    
    func testMessageSerializationPerformance() {
        let messages = (1...1000).map { i in
            LLMMessage(role: i % 2 == 0 ? "user" : "assistant", content: "Test message \(i)")
        }
        
        measure {
            let encoder = JSONEncoder()
            for message in messages {
                _ = try? encoder.encode(message)
            }
        }
    }
    
    func testConversationPerformance() {
        measure {
            var conversation = Conversation()
            for i in 1...1000 {
                if i % 2 == 0 {
                    conversation.addUserMessage("User message \(i)")
                } else {
                    conversation.addAssistantMessage("Assistant message \(i)")
                }
            }
            XCTAssertEqual(conversation.messages.count, 1000)
        }
    }
    
    func testStringExtensionPerformance() {
        let testStrings = (1...1000).map { i in "Test string number \(i) with some content" }
        
        measure {
            for string in testStrings {
                _ = string.isNotEmpty
                _ = string.sanitized()
                _ = string.truncated(to: 10)
            }
        }
    }
    
    func testLLMRequestCreationPerformance() {
        let baseMessages = [
            LLMMessage(role: "system", content: "You are a helpful assistant"),
            LLMMessage(role: "user", content: "Hello, how are you?")
        ]
        
        measure {
            for _ in 1...1000 {
                _ = LLMRequest(messages: baseMessages)
            }
        }
    }
    
    func testDataExtensionPerformance() {
        let testData = (1...100).map { "Test data string \($0)".data(using: .utf8)! }
        
        measure {
            for data in testData {
                _ = data.humanReadableSize
            }
        }
    }
}