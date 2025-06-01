import Foundation
import os.log

enum LogLevel {
    case debug
    case info
    case warning
    case error
}

class Logger {
    static let shared = Logger()
    private let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "AIAgent", category: "general")
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            os_log("%{public}@", log: osLog, type: .debug, formattedMessage)
        case .info:
            os_log("%{public}@", log: osLog, type: .info, formattedMessage)
        case .warning:
            os_log("%{public}@", log: osLog, type: .default, formattedMessage)
        case .error:
            os_log("%{public}@", log: osLog, type: .error, formattedMessage)
        }
        
        #if DEBUG
        print("[\(level)] \(formattedMessage)")
        #endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}