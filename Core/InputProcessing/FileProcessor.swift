import Foundation
import UniformTypeIdentifiers
import AppKit

class FileProcessor {
    
    // MARK: - File Type Detection
    
    static let supportedTextTypes: [UTType] = [
        .plainText, .utf8PlainText, .sourceCode, .json, .xml,
        .html, .rtf, .pdf
    ]
    
    static let supportedImageTypes: [UTType] = [
        .png, .jpeg, .gif, .bmp, .tiff, .heic, .webP
    ]
    
    static let supportedAudioTypes: [UTType] = [
        .mp3, .wav, .aiff
    ]
    
    static let supportedVideoTypes: [UTType] = [
        .quickTimeMovie, .avi
    ]
    
    // MARK: - File Processing
    
    func processFile(at url: URL) async throws -> InputEvent {
        guard url.startAccessingSecurityScopedResource() else {
            throw FileProcessorError.securityScopedResourceAccessFailed
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        let fileType = try detectFileType(at: url)
        let fileData = try Data(contentsOf: url)
        
        var metadata: [String: Any] = [
            "filename": url.lastPathComponent,
            "fileSize": fileData.count,
            "filePath": url.path,
            "fileType": fileType.identifier
        ]
        
        // Add file-specific metadata
        switch fileType {
        case _ where Self.supportedTextTypes.contains(fileType):
            metadata["textContent"] = try processTextFile(data: fileData, type: fileType)
            return InputEvent(type: .file, content: fileData, metadata: metadata)
            
        case _ where Self.supportedImageTypes.contains(fileType):
            metadata.merge(try processImageFile(data: fileData)) { _, new in new }
            return InputEvent(type: .image, content: fileData, metadata: metadata)
            
        case _ where Self.supportedAudioTypes.contains(fileType):
            metadata.merge(try processAudioFile(at: url)) { _, new in new }
            return InputEvent(type: .audio, content: fileData, metadata: metadata)
            
        case _ where Self.supportedVideoTypes.contains(fileType):
            metadata.merge(try processVideoFile(at: url)) { _, new in new }
            return InputEvent(type: .video, content: fileData, metadata: metadata)
            
        default:
            // Generic file processing
            return InputEvent(type: .file, content: fileData, metadata: metadata)
        }
    }
    
    func processMultipleFiles(urls: [URL]) async throws -> [InputEvent] {
        var events: [InputEvent] = []
        
        for url in urls {
            do {
                let event = try await processFile(at: url)
                events.append(event)
            } catch {
                Logger.shared.error("Failed to process file \(url.lastPathComponent): \(error)")
                // Continue processing other files
            }
        }
        
        return events
    }
    
    // MARK: - File Type Detection
    
    private func detectFileType(at url: URL) throws -> UTType {
        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
        guard let contentType = resourceValues.contentType else {
            throw FileProcessorError.unableToDetectFileType
        }
        return contentType
    }
    
    // MARK: - Text File Processing
    
    private func processTextFile(data: Data, type: UTType) throws -> String {
        if type == .pdf {
            return try processPDFFile(data: data)
        }
        
        // Try different encodings
        let encodings: [String.Encoding] = [.utf8, .utf16, .ascii, .isoLatin1]
        
        for encoding in encodings {
            if let content = String(data: data, encoding: encoding) {
                return content
            }
        }
        
        throw FileProcessorError.unableToDecodeTextFile
    }
    
    private func processPDFFile(data: Data) throws -> String {
        // Note: This is a basic implementation. For production, consider using PDFKit
        // For now, return a placeholder that indicates PDF content
        return "[PDF Document - \(data.count) bytes]"
    }
    
    // MARK: - Image File Processing
    
    private func processImageFile(data: Data) throws -> [String: Any] {
        guard let image = NSImage(data: data) else {
            throw FileProcessorError.unableToProcessImageFile
        }
        
        var metadata: [String: Any] = [
            "imageWidth": image.size.width,
            "imageHeight": image.size.height,
            "imageFormat": detectImageFormat(data: data)
        ]
        
        // Extract basic image properties
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            metadata["colorSpace"] = cgImage.colorSpace?.name ?? "Unknown"
            metadata["bitsPerComponent"] = cgImage.bitsPerComponent
            metadata["bitsPerPixel"] = cgImage.bitsPerPixel
        }
        
        return metadata
    }
    
    private func detectImageFormat(data: Data) -> String {
        guard data.count >= 4 else { return "Unknown" }
        
        let bytes = data.prefix(4)
        
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "JPEG"
        } else if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "PNG"
        } else if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return "GIF"
        } else if bytes.starts(with: [0x42, 0x4D]) {
            return "BMP"
        }
        
        return "Unknown"
    }
    
    // MARK: - Audio File Processing
    
    private func processAudioFile(at url: URL) throws -> [String: Any] {
        // Basic audio file metadata
        // For more detailed metadata, consider using AVFoundation
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        
        return [
            "audioFileSize": fileSize,
            "audioFormat": url.pathExtension.uppercased()
        ]
    }
    
    // MARK: - Video File Processing
    
    private func processVideoFile(at url: URL) throws -> [String: Any] {
        // Basic video file metadata
        // For more detailed metadata, consider using AVFoundation
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        
        return [
            "videoFileSize": fileSize,
            "videoFormat": url.pathExtension.uppercased()
        ]
    }
    
    // MARK: - File Validation
    
    func validateFile(at url: URL) throws -> Bool {
        // Check if file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FileProcessorError.fileNotFound
        }
        
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw FileProcessorError.fileNotReadable
        }
        
        // Check file size (limit to 100MB)
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard fileSize <= 100 * 1024 * 1024 else {
            throw FileProcessorError.fileTooLarge
        }
        
        return true
    }
    
    func isSupportedFileType(_ url: URL) -> Bool {
        guard let fileType = try? detectFileType(at: url) else {
            return false
        }
        
        let allSupportedTypes = Self.supportedTextTypes + 
                               Self.supportedImageTypes + 
                               Self.supportedAudioTypes + 
                               Self.supportedVideoTypes
        
        return allSupportedTypes.contains { supportedType in
            fileType.conforms(to: supportedType)
        }
    }
}

// MARK: - Error Types

enum FileProcessorError: Error, LocalizedError {
    case fileNotFound
    case fileNotReadable
    case fileTooLarge
    case unableToDetectFileType
    case unableToDecodeTextFile
    case unableToProcessImageFile
    case securityScopedResourceAccessFailed
    case unsupportedFileType
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .fileNotReadable:
            return "File is not readable"
        case .fileTooLarge:
            return "File is too large (maximum 100MB)"
        case .unableToDetectFileType:
            return "Unable to detect file type"
        case .unableToDecodeTextFile:
            return "Unable to decode text file"
        case .unableToProcessImageFile:
            return "Unable to process image file"
        case .securityScopedResourceAccessFailed:
            return "Failed to access security-scoped resource"
        case .unsupportedFileType:
            return "Unsupported file type"
        }
    }
}