import Foundation

struct Constants {
    
    // App Configuration
    static let appName = "AI Agent"
    static let appVersion = "1.0.0"
    static let bundleIdentifier = "com.aiagent.app"
    
    // UI Constants
    static let windowDefaultWidth: CGFloat = 800
    static let windowDefaultHeight: CGFloat = 600
    static let windowMinWidth: CGFloat = 400
    static let windowMinHeight: CGFloat = 300
    
    // Chat UI
    static let chatBubbleMaxWidth: CGFloat = 500
    static let chatBubbleCornerRadius: CGFloat = 12
    static let chatSpacing: CGFloat = 12
    static let chatPadding: CGFloat = 16
    
    // API Configuration
    static let defaultModel = "claude-3-sonnet-20240229"
    static let defaultMaxTokens = 4000
    static let apiVersion = "2023-06-01"
    
    // File Operations
    static let maxFileSize: Int = 50 * 1024 * 1024 // 50MB
    static let supportedImageFormats = ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]
    static let supportedAudioFormats = ["mp3", "wav", "m4a", "aac"]
    static let supportedVideoFormats = ["mp4", "mov", "avi", "mkv"]
    
    // System
    static let maxConversationHistory = 1000
    static let cacheExpiration: TimeInterval = 3600 // 1 hour
    
    // Error Messages
    struct ErrorMessages {
        static let noAPIKey = "No API key provided. Please set ANTHROPIC_API_KEY environment variable or configure in settings."
        static let networkError = "Network error occurred. Please check your internet connection."
        static let invalidResponse = "Invalid response from AI service."
        static let fileOperationFailed = "File operation failed."
        static let unsupportedFileType = "Unsupported file type."
    }
    
    // Notifications
    struct Notifications {
        static let configurationChanged = Notification.Name("ConfigurationChanged")
        static let conversationUpdated = Notification.Name("ConversationUpdated")
        static let toolExecutionCompleted = Notification.Name("ToolExecutionCompleted")
    }
}