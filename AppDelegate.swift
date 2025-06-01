import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("App launched!")
        NSApp.setActivationPolicy(.regular)
        
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        print("Window created")
        window.title = "Hello World App"
        window.isReleasedWhenClosed = false
        
        let viewController = ViewController()
        window.contentViewController = viewController
        
        print("About to show window")
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        print("Window should be visible now")
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}