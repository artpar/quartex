import Cocoa
import UniformTypeIdentifiers

class ViewController: NSViewController {
    
    private var aiAgent: AIAgent!
    private var inputCoordinator: InputCoordinator!
    private var audioService: AudioService!
    private var scrollView: NSScrollView!
    private var chatContainer: NSStackView!
    private var inputField: NSTextField!
    private var sendButton: NSButton!
    private var audioButton: NSButton!
    private var fileButton: NSButton!
    private var dropZone: FileDropZone!
    private var currentStreamingView: StreamingTextView?
    private var isRecording = false
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        aiAgent = AIAgent()
        inputCoordinator = InputCoordinator()
        audioService = AudioService()
        inputCoordinator.delegate = self
        setupChatUI()
        requestPermissions()
    }
    
    private func setupChatUI() {
        setupScrollView()
        setupFileDropZone()
        setupInputArea()
        setupConstraints()
        addWelcomeMessage()
    }
    
    private func setupScrollView() {
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        chatContainer = NSStackView()
        chatContainer.orientation = .vertical
        chatContainer.alignment = .leading
        chatContainer.spacing = 12
        chatContainer.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.documentView = chatContainer
        view.addSubview(scrollView)
    }
    
    private func setupFileDropZone() {
        dropZone = FileDropZone()
        dropZone.translatesAutoresizingMaskIntoConstraints = false
        dropZone.delegate = self
        view.addSubview(dropZone)
    }
    
    private func setupInputArea() {
        let inputContainer = NSView()
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        
        inputField = NSTextField()
        inputField.placeholderString = "Type your message here..."
        inputField.font = NSFont.systemFont(ofSize: 14)
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.target = self
        inputField.action = #selector(sendMessage)
        
        sendButton = NSButton(title: "Send", target: self, action: #selector(sendMessage))
        sendButton.font = NSFont.systemFont(ofSize: 14)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        audioButton = NSButton(title: "🎤", target: self, action: #selector(toggleAudioRecording))
        audioButton.font = NSFont.systemFont(ofSize: 18)
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        audioButton.toolTip = "Record audio message"
        
        fileButton = NSButton(title: "📎", target: self, action: #selector(selectFiles))
        fileButton.font = NSFont.systemFont(ofSize: 18)
        fileButton.translatesAutoresizingMaskIntoConstraints = false
        fileButton.toolTip = "Attach files"
        
        inputContainer.addSubview(fileButton)
        inputContainer.addSubview(audioButton)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)
        view.addSubview(inputContainer)
        
        NSLayoutConstraint.activate([
            fileButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            fileButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            fileButton.widthAnchor.constraint(equalToConstant: 35),
            
            audioButton.leadingAnchor.constraint(equalTo: fileButton.trailingAnchor, constant: 8),
            audioButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            audioButton.widthAnchor.constraint(equalToConstant: 35),
            
            inputField.leadingAnchor.constraint(equalTo: audioButton.trailingAnchor, constant: 8),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputField.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            inputField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            dropZone.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dropZone.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dropZone.topAnchor.constraint(equalTo: view.topAnchor),
            dropZone.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            
            chatContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            chatContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            chatContainer.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            chatContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func addWelcomeMessage() {
        let welcomeText = "Welcome to AI Assistant! I can help you with various tasks including file operations, answering questions, and more. You can:\n\n• Type messages in the text field\n• Click 🎤 to record voice messages\n• Click 📎 to attach files\n• Drag and drop files anywhere\n\nWhat would you like to do?"
        addMessageBubble(text: welcomeText, isUser: false)
    }
    
    private func requestPermissions() {
        Task {
            await inputCoordinator.requestRequiredPermissions()
        }
    }
    
    @objc private func sendMessage() {
        guard !inputField.stringValue.isEmpty else { return }
        
        let userMessage = inputField.stringValue
        addMessageBubble(text: userMessage, isUser: true)
        inputField.stringValue = ""
        
        Task {
            await inputCoordinator.processTextInput(userMessage)
        }
    }
    
    @objc private func toggleAudioRecording() {
        if isRecording {
            stopAudioRecording()
        } else {
            startAudioRecording()
        }
    }
    
    @objc private func selectFiles() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [
            .plainText, .json, .xml, .html,
            .png, .jpeg, .gif, .tiff, .heic,
            .mp3, .wav, .aiff,
            .quickTimeMovie,
            .pdf
        ]
        
        openPanel.begin { [weak self] response in
            if response == .OK {
                let urls = openPanel.urls
                Task {
                    await self?.inputCoordinator.processFileURLs(urls)
                }
            }
        }
    }
    
    private func startAudioRecording() {
        isRecording = true
        audioButton.title = "🔴"
        audioButton.toolTip = "Stop recording"
        addMessageBubble(text: "🎤 Recording audio...", isUser: true)
        
        Task {
            do {
                let recordingURL = try await audioService.startRecording()
                Logger.shared.info("Started recording audio to: \(recordingURL)")
            } catch {
                DispatchQueue.main.async {
                    self.showError("Failed to start recording: \(error.localizedDescription)")
                    self.stopAudioRecording()
                }
            }
        }
    }
    
    private func stopAudioRecording() {
        isRecording = false
        audioButton.title = "🎤"
        audioButton.toolTip = "Record audio message"
        
        guard let recordingURL = audioService.stopRecording() else {
            showError("No recording to stop")
            return
        }
        
        Task {
            do {
                let inputEvent = try audioService.convertToInputEvent(audioURL: recordingURL)
                await inputCoordinator.processInput(inputEvent)
                
                // Clean up the recording file
                try audioService.deleteRecording(at: recordingURL)
            } catch {
                DispatchQueue.main.async {
                    self.showError("Failed to process recording: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func addMessageBubble(text: String, isUser: Bool) {
        let bubbleView = createMessageBubble(text: text, isUser: isUser)
        chatContainer.addArrangedSubview(bubbleView)
        scrollToBottom()
    }
    
    private func createMessageBubble(text: String, isUser: Bool) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let bubble = NSView()
        bubble.wantsLayer = true
        bubble.layer?.cornerRadius = 12
        bubble.layer?.backgroundColor = isUser ? NSColor.systemBlue.cgColor : NSColor.controlBackgroundColor.cgColor
        bubble.translatesAutoresizingMaskIntoConstraints = false
        
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = isUser ? NSColor.white : NSColor.labelColor
        label.backgroundColor = NSColor.clear
        label.translatesAutoresizingMaskIntoConstraints = false
        
        bubble.addSubview(label)
        container.addSubview(bubble)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),
            
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 500),
            bubble.topAnchor.constraint(equalTo: container.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        
        if isUser {
            bubble.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
            bubble.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 100).isActive = true
        } else {
            bubble.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            bubble.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -100).isActive = true
        }
        
        return container
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.async {
            let contentHeight = self.chatContainer.fittingSize.height
            let scrollViewHeight = self.scrollView.contentSize.height
            
            if contentHeight > scrollViewHeight {
                let scrollPoint = NSPoint(x: 0, y: contentHeight - scrollViewHeight)
                self.scrollView.contentView.scroll(to: scrollPoint)
            }
        }
    }
}

// MARK: - InputCoordinatorDelegate

extension ViewController: InputCoordinatorDelegate {
    func inputCoordinator(_ coordinator: InputCoordinator, didProcessInput event: InputEvent, result: String) {
        DispatchQueue.main.async {
            // Add processing result message
            let processingMessage = self.formatInputEventMessage(event: event, result: result)
            self.addMessageBubble(text: processingMessage, isUser: true)
            
            // Add streaming response bubble
            let streamingView = StreamingTextView(isUser: false)
            self.currentStreamingView = streamingView
            self.chatContainer.addArrangedSubview(streamingView)
            streamingView.startStreaming()
            self.scrollToBottom()
            
            Task {
                await self.aiAgent.processUserInput(result) { [weak self] partialResponse in
                    DispatchQueue.main.async {
                        self?.currentStreamingView?.updateStreamingText(partialResponse)
                        self?.scrollToBottom()
                    }
                }
                
                DispatchQueue.main.async {
                    self.currentStreamingView?.finishStreaming()
                    self.currentStreamingView = nil
                    self.scrollToBottom()
                }
            }
        }
    }
    
    func inputCoordinator(_ coordinator: InputCoordinator, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.showError("Input processing failed: \(error.localizedDescription)")
        }
    }
    
    func inputCoordinator(_ coordinator: InputCoordinator, didStartProcessing inputType: InputType) {
        DispatchQueue.main.async {
            let processingMessage = "Processing \(inputType.displayName)..."
            self.addMessageBubble(text: processingMessage, isUser: false)
        }
    }
    
    func inputCoordinator(_ coordinator: InputCoordinator, didFinishProcessing inputType: InputType) {
        // Implementation can be added if needed for progress tracking
    }
    
    private func formatInputEventMessage(event: InputEvent, result: String) -> String {
        switch event.type {
        case .text:
            return result
        case .audio:
            if let duration = event.metadata["duration"] as? TimeInterval {
                return "🎤 Audio (\(String(format: "%.1f", duration))s): \(result)"
            }
            return "🎤 Audio: \(result)"
        case .image:
            if let filename = event.metadata["filename"] as? String {
                return "🖼️ Image (\(filename)): \(result)"
            }
            return "🖼️ Image: \(result)"
        case .file:
            if let filename = event.metadata["filename"] as? String {
                return "📄 File (\(filename)): \(result)"
            }
            return "📄 File: \(result)"
        case .video:
            if let filename = event.metadata["filename"] as? String {
                return "🎬 Video (\(filename)): \(result)"
            }
            return "🎬 Video: \(result)"
        }
    }
}

// MARK: - FileDropZoneDelegate

extension ViewController: FileDropZoneDelegate {
    func fileDropZone(_ dropZone: FileDropZone, didReceiveFiles urls: [URL]) {
        Task {
            await inputCoordinator.processFileURLs(urls)
        }
    }
}

// MARK: - InputType Extension

extension InputType {
    var displayName: String {
        switch self {
        case .text: return "text"
        case .audio: return "audio"
        case .video: return "video"
        case .file: return "file"
        case .image: return "image"
        }
    }
}