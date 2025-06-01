import Foundation

struct LLMMessage: Codable {
    let role: String
    let content: String
}

struct LLMRequest: Codable {
    let model: String
    let messages: [LLMMessage]
    let stream: Bool
    let max_tokens: Int?
    
    init(model: String = "claude-3-sonnet-20240229", messages: [LLMMessage], stream: Bool = true, maxTokens: Int? = 4000) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.max_tokens = maxTokens
    }
}

struct LLMResponse: Codable {
    let id: String?
    let choices: [LLMChoice]?
    let delta: LLMDelta?
}

struct LLMChoice: Codable {
    let message: LLMMessage?
    let delta: LLMDelta?
    let finish_reason: String?
}

struct LLMDelta: Codable {
    let content: String?
}