import Cocoa

class ViewController: NSViewController {
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let label = NSTextField(labelWithString: "Welcome to Hello World App!")
        label.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = NSColor.labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let actionButton = NSButton(title: "Click Me!", target: self, action: #selector(buttonClicked))
        actionButton.font = NSFont.systemFont(ofSize: 16)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        let quitButton = NSButton(title: "Quit App", target: self, action: #selector(quitApp))
        quitButton.font = NSFont.systemFont(ofSize: 14)
        quitButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        view.addSubview(actionButton)
        view.addSubview(quitButton)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            label.widthAnchor.constraint(equalToConstant: 300),
            label.heightAnchor.constraint(equalToConstant: 50),
            
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 32),
            
            quitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quitButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 20),
            quitButton.widthAnchor.constraint(equalToConstant: 80),
            quitButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    @objc private func buttonClicked() {
        let alert = NSAlert()
        alert.messageText = "Button Clicked!"
        alert.informativeText = "You clicked the button on the home screen."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}