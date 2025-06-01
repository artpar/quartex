import Foundation

public struct Constants {
    
    // App Configuration
    public static let appName = "AI Agent"
    public static let appVersion = "1.0.0"
    public static let bundleIdentifier = "com.aiagent.app"
    
    // UI Constants
    public static let windowDefaultWidth: CGFloat = 800
    public static let windowDefaultHeight: CGFloat = 600
    public static let windowMinWidth: CGFloat = 400
    public static let windowMinHeight: CGFloat = 300
    
    // Chat UI
    public static let chatBubbleMaxWidth: CGFloat = 500
    public static let chatBubbleCornerRadius: CGFloat = 12
    public static let chatSpacing: CGFloat = 12
    public static let chatPadding: CGFloat = 16
    
    // API Configuration
    public static let defaultModel = "claude-3-sonnet-20240229"
    public static let defaultMaxTokens = 4000
    public static let apiVersion = "2023-06-01"
    
    // File Operations
    public static let maxFileSize: Int = 50 * 1024 * 1024 // 50MB
    public static let supportedImageFormats = ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]
    public static let supportedAudioFormats = ["mp3", "wav", "m4a", "aac"]
    public static let supportedVideoFormats = ["mp4", "mov", "avi", "mkv"]
    
    // System
    public static let maxConversationHistory = 1000
    public static let cacheExpiration: TimeInterval = 3600 // 1 hour
    
    // Error Messages
    public struct ErrorMessages {
        public static let noAPIKey = "No API key provided. Please set ANTHROPIC_API_KEY environment variable or configure in settings."
        public static let networkError = "Network error occurred. Please check your internet connection."
        public static let invalidResponse = "Invalid response from AI service."
        public static let fileOperationFailed = "File operation failed."
        public static let unsupportedFileType = "Unsupported file type."
    }
    
    // Notifications
    public struct Notifications {
        public static let configurationChanged = Notification.Name("ConfigurationChanged")
        public static let conversationUpdated = Notification.Name("ConversationUpdated")
        public static let toolExecutionCompleted = Notification.Name("ToolExecutionCompleted")
    }
}