import Foundation

struct Conversation {
    var messages: [LLMMessage] = []
    let id = UUID()
    
    mutating func addMessage(_ message: LLMMessage) {
        messages.append(message)
    }
    
    mutating func addUserMessage(_ content: String) {
        addMessage(LLMMessage(role: "user", content: content))
    }
    
    mutating func addAssistantMessage(_ content: String) {
        addMessage(LLMMessage(role: "assistant", content: content))
    }
}