import Foundation

enum InputType {
    case text
    case audio
    case video
    case file
    case image
}

struct InputEvent {
    let id = UUID()
    let type: InputType
    let content: Data
    let metadata: [String: Any]
    let timestamp: Date
    
    init(type: InputType, content: Data, metadata: [String: Any] = [:]) {
        self.type = type
        self.content = content
        self.metadata = metadata
        self.timestamp = Date()
    }
}