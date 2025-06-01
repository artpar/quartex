import Foundation
import Cocoa

// MARK: - String Extensions
extension String {
    var isNotEmpty: Bool {
        return !isEmpty
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
    
    func sanitized() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Data Extensions
extension Data {
    var humanReadableSize: String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: Int64(count))
    }
}

// MARK: - URL Extensions
extension URL {
    var fileSize: Int64 {
        do {
            let resourceValues = try resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    var isImageFile: Bool {
        return Constants.supportedImageFormats.contains(pathExtension.lowercased())
    }
    
    var isAudioFile: Bool {
        return Constants.supportedAudioFormats.contains(pathExtension.lowercased())
    }
    
    var isVideoFile: Bool {
        return Constants.supportedVideoFormats.contains(pathExtension.lowercased())
    }
}

// MARK: - Date Extensions
extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var chatTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - NSColor Extensions
extension NSColor {
    static var chatUserBubble: NSColor {
        return NSColor.systemBlue
    }
    
    static var chatAssistantBubble: NSColor {
        return NSColor.controlBackgroundColor
    }
    
    static var chatBackground: NSColor {
        return NSColor.windowBackgroundColor
    }
}

// MARK: - Result Extensions
extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
}