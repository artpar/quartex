# AI-First macOS Application - Claude Context

## Project Overview

This is an AI-first macOS application built in Swift that transforms user inputs (text, audio, video) into actions through LLM-powered decision making. The application serves as a universal interface where every functionality is delegated to an AI agent that can utilize various tools and plugins.

## Current State

**Existing Files:**
- `main.swift` - App entry point with NSApplicationMain
- `AppDelegate.swift` - Window creation and app lifecycle management  
- Complete Core infrastructure with AIAgent, LLMClient, Models, Utils
- Comprehensive test suite with 72 tests (0 failures)
- `Makefile` - Enhanced build system with testing targets
- `Info.plist` - App metadata
- `config.json` - Configuration with Anthropic API integration

**Current Functionality:**
- Fully functional chat interface with real-time streaming text
- Working Anthropic Claude API integration with proper authentication
- Complete tool system with file operations (read/write/create/list)
- Multi-turn conversation support with context retention
- Character-by-character streaming UI with visual cursor
- Comprehensive error handling and logging
- Extensive test coverage (Unit, Integration, Performance, Security, UI)

## Architecture Overview

### Core Design Principles
1. **Agent-Centric**: Single AIAgent orchestrates all interactions
2. **LLM-Driven**: Every functionality decision made through /completions API
3. **Multi-Modal**: Support for text, audio, video, and file inputs
4. **Tool-Based**: Extensible system of tools/functions the AI can invoke
5. **Plugin Architecture**: Third-party extensibility through plugins

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Layer      │◄──►│   AI Agent      │◄──►│  Tool System    │
│                 │    │     Core        │    │                 │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • Chat Interface│    │ • LLM Client    │    │ • System Tools  │
│ • Input Capture │    │ • Context Mgmt  │    │ • File Tools    │
│ • Media Display │    │ • Conversation  │    │ • Web Tools     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └──────────────►│  Input Layer    │◄─────────────┘
                        │                 │
                        │ • Text Processor│
                        │ • Audio Handler │
                        │ • Video Analyzer│
                        └─────────────────┘
```

## Project Structure Plan

```
/
├── Core/
│   ├── AIAgent/
│   │   ├── AIAgent.swift              # Central orchestrator
│   │   ├── LLMClient.swift            # /completions API client
│   │   ├── ConversationManager.swift  # Chat history & context
│   │   ├── ContextManager.swift       # System context tracking
│   │   └── StreamingHandler.swift     # Real-time response streaming
│   │
│   ├── InputProcessing/
│   │   ├── InputCoordinator.swift     # Multi-modal input router
│   │   ├── TextProcessor.swift        # Text analysis & preprocessing
│   │   ├── AudioProcessor.swift       # Speech-to-text conversion
│   │   ├── VideoProcessor.swift       # Video frame analysis
│   │   └── FileProcessor.swift        # Document/image processing
│   │
│   ├── ToolSystem/
│   │   ├── ToolRegistry.swift         # Available tools catalog
│   │   ├── ToolExecutor.swift         # Tool invocation engine
│   │   ├── FunctionCalling.swift      # LLM function call parsing
│   │   └── Tools/
│   │       ├── SystemTools.swift      # OS integration
│   │       ├── FileTools.swift        # File operations
│   │       ├── WebTools.swift         # Web browsing/requests
│   │       ├── AppTools.swift         # App control/automation
│   │       └── MediaTools.swift       # Audio/video manipulation
│   │
│   └── Extensions/
│       ├── PluginManager.swift        # Plugin lifecycle management
│       ├── PluginProtocol.swift       # Plugin interface definition
│       └── SecurityManager.swift      # Sandboxing & permissions
│
├── UI/
│   ├── Components/
│   │   ├── ChatViewController.swift   # Main chat interface
│   │   ├── InputArea.swift           # Multi-modal input component
│   │   ├── MessageBubble.swift       # Chat message display
│   │   ├── MediaViewer.swift         # Image/video display
│   │   ├── ToolOutputView.swift      # Tool execution results
│   │   └── StreamingTextView.swift   # Real-time text streaming
│   │
│   ├── Windows/
│   │   ├── MainWindow.swift          # Primary app window
│   │   ├── SettingsWindow.swift      # Configuration panel
│   │   └── DebugWindow.swift         # Development tools
│   │
│   └── ViewModels/
│       ├── ChatViewModel.swift       # Chat state management
│       ├── InputViewModel.swift      # Input handling logic
│       └── SettingsViewModel.swift   # Settings state
│
├── Services/
│   ├── AudioService.swift            # Audio capture/playback
│   ├── VideoService.swift            # Camera/screen capture
│   ├── FileService.swift             # File system operations
│   ├── NetworkService.swift          # HTTP/WebSocket client
│   ├── SecurityService.swift         # Permission management
│   └── NotificationService.swift     # User notifications
│
├── Models/
│   ├── Message.swift                 # Chat message model
│   ├── Conversation.swift            # Conversation model
│   ├── Tool.swift                    # Tool definition model
│   ├── Plugin.swift                  # Plugin model
│   ├── InputEvent.swift              # Multi-modal input event
│   └── AIResponse.swift              # LLM response model
│
├── Utils/
│   ├── Logger.swift                  # Logging system
│   ├── Configuration.swift           # App settings
│   ├── Extensions.swift              # Swift extensions
│   ├── Constants.swift               # App constants
│   └── ErrorHandling.swift           # Error management
│
└── Resources/
    ├── Prompts/                      # System prompts
    ├── Plugins/                      # Bundled plugins
    └── Assets/                       # UI assets
```

## Key Components

### AIAgent (Core/AIAgent/AIAgent.swift)
- Central orchestrator for all AI interactions
- Manages conversation flow and context
- Decides which tools to invoke based on user input
- Handles streaming responses from LLM

### LLM Integration
- Uses /completions compatible endpoints
- Supports function calling for tool invocation
- Streaming response handling for real-time updates
- Context window management for long conversations

### Tool System
- Registry of available tools/functions
- Standardized tool interface for easy extension
- Security sandboxing for tool execution
- Built-in tools: file operations, system commands, web browsing, media processing

### Multi-Modal Input Processing
- Text: Direct input processing
- Audio: Speech-to-text using macOS Speech framework
- Video: Frame analysis and content extraction
- Files: Document parsing, image analysis

### Plugin Architecture
```swift
protocol AIPlugin {
    var name: String { get }
    var tools: [Tool] { get }
    func execute(tool: Tool, parameters: [String: Any]) async -> ToolResult
}
```

## Implementation Phases

### Phase 1: Core Infrastructure ✅ COMPLETED
- ✅ Replace current UI with basic chat interface
- ✅ Implement LLM client with /completions API
- ✅ Create basic tool system (file operations, system commands)
- ✅ Set up conversation management
- ✅ Comprehensive test suite with 72 tests passing
- ✅ Real-time streaming UI with character-by-character display

### Phase 2: Multi-Modal Input 🚧 IN PROGRESS
- 🔄 Add audio input with Speech framework
- 🔄 Implement file upload and processing
- 🔄 Add camera/screen capture integration
- 🔄 Create unified input processing pipeline

### Phase 3: Advanced Features
- Implement plugin system
- Add advanced context management
- Create tool chaining and workflow automation
- Implement streaming UI updates

### Phase 4: Polish & Optimization
- Performance optimization and caching
- Security hardening and sandboxing
- Advanced UI features and customization
- Comprehensive testing and error handling

## Development Guidelines

### Dependency Management & Third-Party Libraries

**CRITICAL PRINCIPLE: Always leverage existing Swift libraries and dependencies instead of implementing from scratch.**

#### Pre-Implementation Research
Before implementing any feature or functionality, ALWAYS:

1. **Research awesome-swift first**: Check https://github.com/matteocrippa/awesome-swift for relevant libraries
2. **Evaluate Swift Package Manager ecosystem**: Search for established, well-maintained packages
3. **Consider Apple frameworks**: Use built-in frameworks when available (Foundation, AppKit, etc.)
4. **Prioritize battle-tested solutions**: Prefer libraries with active maintenance, good documentation, and community adoption

#### Recommended Categories & Libraries

**Networking & HTTP:**
- Alamofire - HTTP networking library
- URLSession (built-in) for simple requests
- WebSocket frameworks for real-time communication

**JSON & Data Parsing:**
- Swift's built-in Codable
- SwiftyJSON for complex JSON handling
- ObjectMapper for advanced mapping

**UI & User Experience:**
- SnapKit for Auto Layout
- Lottie for animations
- Charts for data visualization
- Kingfisher for image loading/caching

**Audio/Video Processing:**
- AVFoundation (built-in) for basic A/V
- AudioKit for advanced audio processing
- VideoToolbox for video manipulation

**Database & Persistence:**
- Core Data (built-in) for complex data models
- SQLite.swift for direct SQL access
- Realm for object database

**Async & Reactive Programming:**
- Combine (built-in) for reactive streams
- RxSwift for complex reactive patterns
- AsyncAlgorithms for advanced async operations

**Security & Cryptography:**
- CryptoKit (built-in) for modern crypto
- KeychainAccess for secure storage
- CommonCrypto for legacy compatibility

**Utilities & Extensions:**
- SwifterSwift for common extensions
- Then for cleaner initialization syntax
- Result type (now built-in) for error handling

#### Integration Strategy

1. **Add via Swift Package Manager**: Use SPM for all dependencies when possible
2. **Document choices**: Record why specific libraries were chosen in CLAUDE.md
3. **Version management**: Pin to specific versions for stability
4. **Minimize dependencies**: Avoid multiple libraries for same functionality
5. **Regular updates**: Keep dependencies current but test thoroughly

#### Implementation Workflow

```swift
// BEFORE implementing custom solution:
// 1. Check awesome-swift list
// 2. Search Swift Package Index
// 3. Evaluate existing solutions
// 4. Only implement custom if no suitable library exists

// EXAMPLE: Instead of custom HTTP client
import Alamofire

// EXAMPLE: Instead of custom JSON parsing
import Foundation // Use Codable

// EXAMPLE: Instead of custom image loading
import Kingfisher
```

### Code Style
- Follow Swift naming conventions
- Use async/await for asynchronous operations
- Implement proper error handling with Result types
- Use dependency injection for testability
- **Leverage third-party libraries** instead of reinventing wheels

### Security Considerations
- Sandbox tool execution
- Validate all LLM function calls
- Implement permission system for sensitive operations
- Secure API key storage in Keychain

### Testing Strategy
- Unit tests for core logic components
- Integration tests for LLM interactions
- UI tests for main user workflows
- Performance tests for streaming and tool execution

### Debug Cycle & Development Feedback Strategy

**CRITICAL: Ensuring Claude Code can effectively debug and identify implementation gaps**

#### Real-Time Feedback Mechanisms

1. **Immediate Build Verification**
   ```bash
   # After every code change, run comprehensive verification
   make build-verify     # Build + basic smoke tests
   make ui-verify        # UI-specific validation
   make integration-test # Full integration validation
   ```

2. **Runtime State Inspection**
   ```swift
   // Add debug logging for all UI state changes
   class DebugLogger {
       static func logUIState(_ component: String, state: Any) {
           print("🔍 DEBUG: \(component) state: \(state)")
       }
       
       static func logImplementationGap(_ feature: String, expected: String, actual: String) {
           print("❌ IMPLEMENTATION GAP: \(feature)")
           print("   Expected: \(expected)")
           print("   Actual: \(actual)")
       }
   }
   ```

3. **Automated UI State Validation**
   ```swift
   // UI tests that verify actual implementation vs expected behavior
   func testFeatureActuallyWorks() {
       // Not just "does it compile" but "does it actually work"
       let result = performUserAction()
       XCTAssertNotNil(result, "Feature not actually implemented")
       XCTAssertTrue(result.isWorking, "Feature compiles but doesn't work")
   }
   ```

#### Enhanced Testing for Implementation Gaps

1. **Behavioral Testing (Not Just Compilation)**
   ```swift
   // Test actual functionality, not just interfaces
   func testAudioInputActuallyCaptures() {
       let audioProcessor = AudioProcessor()
       let mockInput = createMockAudioInput()
       
       let result = audioProcessor.processAudio(mockInput)
       
       // Verify it actually processes, not just returns nil
       XCTAssertNotNil(result, "Audio processing not implemented")
       XCTAssertFalse(result!.isEmpty, "Audio processing returns empty result")
   }
   ```

2. **Integration Reality Checks**
   ```swift
   // Test that UI components actually connect to business logic
   func testUIActuallyCallsBusinessLogic() {
       let viewController = ChatViewController()
       var businessLogicCalled = false
       
       // Mock the business logic to detect if it's called
       viewController.aiAgent = MockAIAgent { businessLogicCalled = true }
       
       viewController.sendMessage("test")
       
       XCTAssertTrue(businessLogicCalled, "UI doesn't actually call business logic")
   }
   ```

3. **End-to-End Workflow Validation**
   ```swift
   // Test complete user workflows work end-to-end
   func testCompleteUserWorkflow() {
       // Start app
       let app = launchApp()
       
       // Perform actual user actions
       app.typeText("Hello")
       app.tapSendButton()
       
       // Verify actual results appear (not just UI updates)
       XCTAssertTrue(app.messageExists("Hello"), "Message not actually sent")
       XCTAssertTrue(app.responseExists(), "AI response not actually received")
   }
   ```

#### Development Feedback Tools

1. **Visual Debug Dashboard**
   ```swift
   // Real-time debug window showing component states
   class DebugDashboard: NSWindow {
       func showComponentStatus(_ components: [String: Bool]) {
           // Visual indicator of what's actually working vs placeholder
       }
       
       func showImplementationGaps(_ gaps: [String]) {
           // Clear list of what needs actual implementation
       }
   }
   ```

2. **Implementation Status Tracking**
   ```swift
   enum ImplementationStatus {
       case notStarted
       case placeholder
       case partiallyImplemented
       case fullyImplemented
       case tested
   }
   
   struct ComponentStatus {
       let name: String
       let status: ImplementationStatus
       let lastVerified: Date
   }
   ```

3. **Automated Implementation Gap Detection**
   ```bash
   # Script to detect placeholder implementations
   make detect-placeholders    # Find TODO, placeholder, not implemented
   make verify-implementations # Test all features actually work
   make implementation-report  # Generate status report
   ```

#### Debug-Friendly Architecture

1. **Explicit State Management**
   ```swift
   // Make all state changes observable and debuggable
   @Observable
   class AppState {
       var isAudioRecording: Bool = false {
           didSet { DebugLogger.logStateChange("AudioRecording", isAudioRecording) }
       }
       
       var currentConversation: Conversation? {
           didSet { DebugLogger.logStateChange("Conversation", currentConversation) }
       }
   }
   ```

2. **Component Health Checks**
   ```swift
   protocol HealthCheckable {
       func performHealthCheck() -> HealthStatus
   }
   
   struct HealthStatus {
       let isOperational: Bool
       let issues: [String]
       let recommendations: [String]
   }
   ```

#### Claude Code Development Workflow

1. **Pre-Implementation Phase**
   ```bash
   # Before writing code, establish verification criteria
   make setup-debug-environment
   make create-test-stubs
   make define-success-criteria
   ```

2. **During Implementation**
   ```bash
   # After each significant change
   make quick-verify        # Fast feedback loop
   make test-changed-areas  # Test only what changed
   make integration-smoke   # Quick integration check
   ```

3. **Post-Implementation Verification**
   ```bash
   # Comprehensive verification
   make full-test-suite
   make ui-workflow-test
   make performance-check
   make gap-detection
   ```

#### Makefile Enhancements for Debug Cycle

```makefile
# Enhanced debug and verification targets
build-verify:
	swift build && make quick-test

ui-verify:
	swift test --filter UITests && make ui-smoke-test

gap-detection:
	grep -r "TODO\|PLACEHOLDER\|NOT_IMPLEMENTED" . --include="*.swift"
	make test-implementation-status

implementation-report:
	swift test --verbose | grep -E "(PASS|FAIL|SKIP)"
	make component-health-check

debug-dashboard:
	swift run --target DebugDashboard

real-time-feedback:
	fswatch -o . | xargs -n1 -I{} make quick-verify
```

## Configuration

### Environment Variables
- `ANTHROPIC_API_KEY` or equivalent for LLM API access
- `LLM_ENDPOINT` for custom /completions endpoints
- `DEBUG_MODE` for development features

### Build Commands
- `make` - Build the application
- `make run` - Build and run the application
- `make clean` - Clean build artifacts
- `make install` - Install to /Applications

## Notes for Future Development

1. **Maintain backwards compatibility** when extending the tool system
2. **Plugin security** is critical - implement proper sandboxing
3. **Context management** will be key for long conversations
4. **Performance optimization** needed for real-time streaming
5. **User experience** should prioritize responsiveness and clarity

This architecture ensures maintainability through clear separation of concerns, extensibility via the plugin system, and scalability through modular design.

## TODO Management

This project uses a TODO.md file to track development progress and maintain a working plan. Every Claude CLI session should:

1. **Read TODO.md** at the start to understand current priorities and context
2. **Update TODO.md** as tasks are completed, modified, or new requirements emerge
3. **Maintain CLAUDE.md** with any architectural changes or new insights
4. **Keep project state synchronized** between documentation and actual codebase

### TODO.md Structure
- **Current Phase**: Which implementation phase we're in
- **Active Tasks**: Current development priorities with status
- **Completed Tasks**: Recently finished work for context
- **Next Steps**: Upcoming priorities based on current progress
- **Blockers**: Any issues preventing progress
- **Notes**: Important context or decisions made

### Development Workflow
1. Start each session by reading CLAUDE.md and TODO.md
2. Update TODO.md status before beginning work
3. Document any architectural decisions in CLAUDE.md
4. Update TODO.md with progress before ending session
5. Ensure all changes maintain project consistency