import Foundation

protocol InputCoordinatorDelegate: AnyObject {
    func inputCoordinator(_ coordinator: InputCoordinator, didProcessInput event: InputEvent, result: String)
    func inputCoordinator(_ coordinator: InputCoordinator, didFailWithError error: Error)
    func inputCoordinator(_ coordinator: InputCoordinator, didStartProcessing inputType: InputType)
    func inputCoordinator(_ coordinator: InputCoordinator, didFinishProcessing inputType: InputType)
}

class InputCoordinator {
    weak var delegate: InputCoordinatorDelegate?
    
    private let audioProcessor = AudioProcessor()
    private let fileProcessor = FileProcessor()
    private let textProcessor = TextProcessor()
    private let videoProcessor = VideoProcessor()
    
    private let processingQueue = DispatchQueue(label: "com.aiagent.input.processing", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() {
        Logger.shared.info("InputCoordinator initialized")
    }
    
    // MARK: - Input Processing
    
    func processInput(_ event: InputEvent) async {
        delegate?.inputCoordinator(self, didStartProcessing: event.type)
        
        do {
            let result = try await processInputEvent(event)
            await MainActor.run {
                delegate?.inputCoordinator(self, didProcessInput: event, result: result)
                delegate?.inputCoordinator(self, didFinishProcessing: event.type)
            }
        } catch {
            Logger.shared.error("Failed to process input: \(error)")
            await MainActor.run {
                delegate?.inputCoordinator(self, didFailWithError: error)
                delegate?.inputCoordinator(self, didFinishProcessing: event.type)
            }
        }
    }
    
    func processMultipleInputs(_ events: [InputEvent]) async -> [InputProcessingResult] {
        var results: [InputProcessingResult] = []
        
        for event in events {
            delegate?.inputCoordinator(self, didStartProcessing: event.type)
            
            do {
                let result = try await processInputEvent(event)
                let processingResult = InputProcessingResult(event: event, result: result, error: nil)
                results.append(processingResult)
                
                await MainActor.run {
                    delegate?.inputCoordinator(self, didProcessInput: event, result: result)
                    delegate?.inputCoordinator(self, didFinishProcessing: event.type)
                }
            } catch {
                let processingResult = InputProcessingResult(event: event, result: nil, error: error)
                results.append(processingResult)
                
                Logger.shared.error("Failed to process input: \(error)")
                await MainActor.run {
                    delegate?.inputCoordinator(self, didFailWithError: error)
                    delegate?.inputCoordinator(self, didFinishProcessing: event.type)
                }
            }
        }
        
        return results
    }
    
    // MARK: - Individual Processing Methods
    
    private func processInputEvent(_ event: InputEvent) async throws -> String {
        switch event.type {
        case .text:
            return try await textProcessor.processInputEvent(event)
            
        case .audio:
            return try await audioProcessor.processInputEvent(event)
            
        case .file, .image:
            return try await processFileEvent(event)
            
        case .video:
            return try await videoProcessor.processInputEvent(event)
        }
    }
    
    private func processFileEvent(_ event: InputEvent) async throws -> String {
        // For file and image events, extract text content if available
        if let textContent = event.metadata["textContent"] as? String {
            return textContent
        }
        
        // For images, return description based on metadata
        if event.type == .image {
            return createImageDescription(from: event)
        }
        
        // For other files, return file information
        return createFileDescription(from: event)
    }
    
    private func createImageDescription(from event: InputEvent) -> String {
        var description = "Image file: "
        
        if let filename = event.metadata["filename"] as? String {
            description += filename
        }
        
        if let width = event.metadata["imageWidth"] as? Double,
           let height = event.metadata["imageHeight"] as? Double {
            description += " (\(Int(width))x\(Int(height)))"
        }
        
        if let format = event.metadata["imageFormat"] as? String {
            description += " Format: \(format)"
        }
        
        if let fileSize = event.metadata["fileSize"] as? Int {
            description += " Size: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))"
        }
        
        return description
    }
    
    private func createFileDescription(from event: InputEvent) -> String {
        var description = "File: "
        
        if let filename = event.metadata["filename"] as? String {
            description += filename
        }
        
        if let fileType = event.metadata["fileType"] as? String {
            description += " Type: \(fileType)"
        }
        
        if let fileSize = event.metadata["fileSize"] as? Int {
            description += " Size: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))"
        }
        
        return description
    }
    
    // MARK: - Convenience Methods
    
    func processTextInput(_ text: String) async {
        let textData = text.data(using: .utf8) ?? Data()
        let event = InputEvent(type: .text, content: textData, metadata: ["text": text])
        await processInput(event)
    }
    
    func processFileURL(_ url: URL) async {
        do {
            let event = try await fileProcessor.processFile(at: url)
            await processInput(event)
        } catch {
            await MainActor.run {
                delegate?.inputCoordinator(self, didFailWithError: error)
            }
        }
    }
    
    func processFileURLs(_ urls: [URL]) async {
        do {
            let events = try await fileProcessor.processMultipleFiles(urls: urls)
            _ = await processMultipleInputs(events)
        } catch {
            await MainActor.run {
                delegate?.inputCoordinator(self, didFailWithError: error)
            }
        }
    }
    
    // MARK: - Permission Management
    
    func requestRequiredPermissions() async -> Bool {
        let audioPermissions = await audioProcessor.requestPermissions()
        
        if !audioPermissions {
            Logger.shared.warning("Audio permissions not granted")
        }
        
        return audioPermissions
    }
    
    // MARK: - Validation
    
    func canProcessInputType(_ type: InputType) -> Bool {
        switch type {
        case .text:
            return true
        case .audio:
            return true
        case .file, .image:
            return true
        case .video:
            return true
        }
    }
    
    func validateInputEvent(_ event: InputEvent) -> Bool {
        // Basic validation
        guard !event.content.isEmpty else {
            return false
        }
        
        // Type-specific validation
        switch event.type {
        case .text:
            return event.metadata["text"] is String
        case .audio:
            return event.content.count > 0
        case .file, .image:
            return event.metadata["filename"] is String
        case .video:
            return event.content.count > 0
        }
    }
}

// MARK: - Supporting Types

struct InputProcessingResult {
    let event: InputEvent
    let result: String?
    let error: Error?
    let processingTime: TimeInterval
    
    init(event: InputEvent, result: String?, error: Error?) {
        self.event = event
        self.result = result
        self.error = error
        self.processingTime = Date().timeIntervalSince(event.timestamp)
    }
    
    var isSuccess: Bool {
        return error == nil && result != nil
    }
}