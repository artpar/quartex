import Foundation

struct AIResponse {
    let content: String
    let isStreaming: Bool
    let timestamp: Date
    let conversationId: UUID
    
    init(content: String, isStreaming: Bool = false, conversationId: UUID) {
        self.content = content
        self.isStreaming = isStreaming
        self.timestamp = Date()
        self.conversationId = conversationId
    }
}