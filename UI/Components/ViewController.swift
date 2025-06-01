import Cocoa

class ViewController: NSViewController {
    
    private var aiAgent: AIAgent!
    private var scrollView: NSScrollView!
    private var chatContainer: NSStackView!
    private var inputField: NSTextField!
    private var sendButton: NSButton!
    private var currentStreamingView: StreamingTextView?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        aiAgent = AIAgent()
        setupChatUI()
    }
    
    private func setupChatUI() {
        setupScrollView()
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
        
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)
        view.addSubview(inputContainer)
        
        NSLayoutConstraint.activate([
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
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
        let welcomeText = "Welcome to AI Assistant! I can help you with various tasks, answer questions, and assist with your work.\n\nSimply type your message below and I'll respond. I can help with:\n• Answering questions\n• Problem solving\n• Code assistance\n• General conversation\n\nWhat would you like to talk about?"
        addMessageBubble(text: welcomeText, isUser: false)
    }
    
    @objc private func sendMessage() {
        guard !inputField.stringValue.isEmpty else { return }
        
        let userMessage = inputField.stringValue
        addMessageBubble(text: userMessage, isUser: true)
        inputField.stringValue = ""
        
        // Add streaming response bubble
        let streamingView = StreamingTextView(isUser: false)
        currentStreamingView = streamingView
        chatContainer.addArrangedSubview(streamingView)
        streamingView.startStreaming()
        scrollToBottom()
        
        Task {
            await aiAgent.processUserInput(userMessage) { [weak self] partialResponse in
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