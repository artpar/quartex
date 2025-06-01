# AI-First macOS Application - Claude Context

## Project Overview

This is an AI-first macOS application built in Swift that transforms user inputs (text, audio, video) into actions through LLM-powered decision making. The application serves as a universal interface where every functionality is delegated to an AI agent that can utilize various tools and plugins.

## Current State

**Existing Files:**
- `main.swift` - Basic app entry point with NSApplicationMain
- `AppDelegate.swift` - Window creation and app lifecycle management
- `ViewController.swift` - Simple UI with welcome label and two buttons
- `Makefile` - Build system using swiftc directly
- `Info.plist` - Basic app metadata

**Current Functionality:**
- Single window app (600x400px)
- Welcome label and two buttons ("Click Me!" and "Quit App")
- Basic alert dialog on button click

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

### Phase 1: Core Infrastructure
- Replace current UI with basic chat interface
- Implement LLM client with /completions API
- Create basic tool system (file operations, system commands)
- Set up conversation management

### Phase 2: Multi-Modal Input
- Add audio input with Speech framework
- Implement file upload and processing
- Add camera/screen capture integration
- Create unified input processing pipeline

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

### Code Style
- Follow Swift naming conventions
- Use async/await for asynchronous operations
- Implement proper error handling with Result types
- Use dependency injection for testability

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