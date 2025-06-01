import Cocoa
import UniformTypeIdentifiers

protocol FileDropZoneDelegate: AnyObject {
    func fileDropZone(_ dropZone: FileDropZone, didReceiveFiles urls: [URL])
}

class FileDropZone: NSView {
    weak var delegate: FileDropZoneDelegate?
    
    private var isDragHighlighted = false
    private let supportedTypes: [UTType] = [
        .plainText, .json, .xml, .html, .rtf, .pdf,
        .png, .jpeg, .gif, .tiff, .heic,
        .mp3, .wav, .aiff,
        .quickTimeMovie
    ]
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDropZone()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDropZone()
    }
    
    private func setupDropZone() {
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isDragHighlighted {
            // Draw drag highlight overlay
            NSColor.systemBlue.withAlphaComponent(0.1).setFill()
            dirtyRect.fill()
            
            // Draw dashed border
            let path = NSBezierPath(rect: bounds.insetBy(dx: 10, dy: 10))
            path.lineWidth = 3
            path.setLineDash([10, 5], count: 2, phase: 0)
            NSColor.systemBlue.setStroke()
            path.stroke()
            
            // Draw drop message
            let message = "Drop files here"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: NSColor.systemBlue
            ]
            
            let attributedString = NSAttributedString(string: message, attributes: attributes)
            let textSize = attributedString.size()
            let textRect = NSRect(
                x: (bounds.width - textSize.width) / 2,
                y: (bounds.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedString.draw(in: textRect)
        }
    }
    
    // MARK: - Drag and Drop Support
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let urls = getURLsFromDraggingInfo(sender) else {
            return []
        }
        
        // Check if at least one file is supported
        let supportedFiles = urls.filter { url in
            guard let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                return false
            }
            return supportedTypes.contains { supportedType in
                fileType.conforms(to: supportedType)
            }
        }
        
        if !supportedFiles.isEmpty {
            isDragHighlighted = true
            needsDisplay = true
            return .copy
        }
        
        return []
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragHighlighted = false
        needsDisplay = true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDragHighlighted = false
        needsDisplay = true
        
        guard let urls = getURLsFromDraggingInfo(sender) else {
            return false
        }
        
        // Filter for supported files
        let supportedFiles = urls.filter { url in
            guard let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                return false
            }
            return supportedTypes.contains { supportedType in
                fileType.conforms(to: supportedType)
            }
        }
        
        if !supportedFiles.isEmpty {
            delegate?.fileDropZone(self, didReceiveFiles: supportedFiles)
            return true
        }
        
        return false
    }
    
    private func getURLsFromDraggingInfo(_ sender: NSDraggingInfo) -> [URL]? {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: .fileURL) as? [String] else {
            return nil
        }
        
        return pasteboard.compactMap { URL(string: $0) }
    }
}