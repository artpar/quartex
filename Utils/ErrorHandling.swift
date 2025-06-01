import Foundation

public enum AIAgentError: Error, LocalizedError {
    case noAPIKey
    case noData
    case invalidResponse
    case networkError(Error)
    case fileOperationFailed(String)
    case toolExecutionFailed(String)
    case configurationError(String)
    case unsupportedFileType(String)
    case invalidInput(String)
    
    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return Constants.ErrorMessages.noAPIKey
        case .noData:
            return "No data received from AI service."
        case .invalidResponse:
            return Constants.ErrorMessages.invalidResponse
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .fileOperationFailed(let details):
            return "File operation failed: \(details)"
        case .toolExecutionFailed(let details):
            return "Tool execution failed: \(details)"
        case .configurationError(let details):
            return "Configuration error: \(details)"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .noAPIKey:
            return "Please set your API key in the configuration or environment variables."
        case .networkError:
            return "Please check your internet connection and try again."
        case .fileOperationFailed:
            return "Check file permissions and path."
        case .configurationError:
            return "Please check your configuration settings."
        case .unsupportedFileType:
            return "Please use a supported file format."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}

class ErrorHandler {
    static let shared = ErrorHandler()
    private let logger = Logger.shared
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        let contextPrefix = context.isEmpty ? "" : "[\(context)] "
        logger.error("\(contextPrefix)\(error.localizedDescription)")
        
        if let aiError = error as? AIAgentError {
            logger.error("Recovery suggestion: \(aiError.recoverySuggestion ?? "None")")
        }
        
        NotificationCenter.default.post(
            name: .errorOccurred,
            object: nil,
            userInfo: ["error": error, "context": context]
        )
    }
    
    func handleAndReturn<T>(_ error: Error, context: String = "", fallback: T) -> T {
        handle(error, context: context)
        return fallback
    }
}

extension Notification.Name {
    static let errorOccurred = Notification.Name("ErrorOccurred")
}