import Cocoa

print("Starting app...")
let app = NSApplication.shared
print("App created")
let delegate = AppDelegate()
print("Delegate created")
app.delegate = delegate
print("Delegate assigned")
print("Starting main loop...")
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)