import Cocoa

class StreamingTextView: NSView {
    private let textField: NSTextField
    private let bubbleView: NSView
    private var fullText: String = ""
    private var displayedText: String = ""
    private var streamingTimer: Timer?
    private let isUser: Bool
    
    init(isUser: Bool = false) {
        self.isUser = isUser
        
        // Create bubble view
        self.bubbleView = NSView()
        self.bubbleView.wantsLayer = true
        self.bubbleView.layer?.cornerRadius = 12
        self.bubbleView.layer?.backgroundColor = isUser ? NSColor.systemBlue.cgColor : NSColor.controlBackgroundColor.cgColor
        self.bubbleView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create text field
        self.textField = NSTextField(wrappingLabelWithString: "")
        self.textField.font = NSFont.systemFont(ofSize: 14)
        self.textField.textColor = isUser ? NSColor.white : NSColor.labelColor
        self.textField.backgroundColor = NSColor.clear
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        bubbleView.addSubview(textField)
        addSubview(bubbleView)
        
        NSLayoutConstraint.activate([
            // Text field constraints
            textField.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            textField.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            
            // Bubble constraints
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 500),
            bubbleView.topAnchor.constraint(equalTo: topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Container constraints
            heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        
        // User messages align right, assistant messages align left
        if isUser {
            bubbleView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 100).isActive = true
        } else {
            bubbleView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -100).isActive = true
        }
    }
    
    // Set text immediately (for user messages or completed responses)
    func setText(_ text: String) {
        fullText = text
        displayedText = text
        DispatchQueue.main.async {
            self.textField.stringValue = text
        }
    }
    
    // Start streaming text with animation
    func startStreaming(with initialText: String = "") {
        fullText = initialText
        displayedText = ""
        
        DispatchQueue.main.async {
            self.textField.stringValue = ""
            self.addCursor()
        }
    }
    
    // Update streaming text
    func updateStreamingText(_ newFullText: String) {
        fullText = newFullText
        
        DispatchQueue.main.async {
            self.animateToCurrentText()
        }
    }
    
    // Finish streaming and show final text
    func finishStreaming() {
        streamingTimer?.invalidate()
        streamingTimer = nil
        
        DispatchQueue.main.async {
            self.textField.stringValue = self.fullText
            self.removeCursor()
        }
    }
    
    private func animateToCurrentText() {
        guard displayedText.count < fullText.count else { return }
        
        // Stop any existing timer
        streamingTimer?.invalidate()
        
        // Start character-by-character animation
        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.displayedText.count < self.fullText.count {
                let nextIndex = self.fullText.index(self.fullText.startIndex, offsetBy: self.displayedText.count + 1)
                self.displayedText = String(self.fullText[..<nextIndex])
                self.textField.stringValue = self.displayedText + "|"
            } else {
                timer.invalidate()
                self.textField.stringValue = self.fullText + "|"
            }
        }
    }
    
    private func addCursor() {
        textField.stringValue = "|"
    }
    
    private func removeCursor() {
        let text = textField.stringValue
        if text.hasSuffix("|") {
            textField.stringValue = String(text.dropLast())
        }
    }
    
    // Check if currently streaming
    var isStreaming: Bool {
        return streamingTimer?.isValid ?? false
    }
}