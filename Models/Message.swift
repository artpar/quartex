import Foundation

struct LLMMessage: Codable {
    let role: String
    let content: String
}

struct LLMRequest: Codable {
    let model: String
    let messages: [LLMMessage]
    let stream: Bool
    let max_tokens: Int
    
    init(model: String = "claude-3-sonnet-20240229", messages: [LLMMessage], stream: Bool = true, maxTokens: Int = 4000) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.max_tokens = maxTokens
    }
}

// Anthropic Messages API Response Format
struct LLMResponse: Codable {
    let id: String?
    let type: String?
    let role: String?
    let content: [LLMContent]?
    let model: String?
    let stop_reason: String?
    let usage: LLMUsage?
    
    // For streaming responses
    let delta: LLMDelta?
}

struct LLMContent: Codable {
    let type: String
    let text: String?
}

struct LLMUsage: Codable {
    let input_tokens: Int?
    let output_tokens: Int?
}

struct LLMDelta: Codable {
    let type: String?
    let text: String?
    let stop_reason: String?
}