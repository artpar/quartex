# Quartex

An AI-first macOS application that transforms multi-modal user inputs into intelligent actions through LLM-powered decision making.

[![Build Status](https://github.com/artpar/quartex/workflows/CI/badge.svg)](https://github.com/artpar/quartex/actions)
[![Swift Version](https://img.shields.io/badge/swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-lightgrey.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Overview

Quartex is a revolutionary macOS application that serves as a universal interface where every functionality is delegated to an AI agent powered by large language models. Instead of traditional UI interactions, users communicate through natural language, and the AI agent intelligently interprets requests and executes appropriate actions through an extensible tool system.

### Key Concepts

- **Agent-Centric Design**: A single AIAgent orchestrates all interactions
- **LLM-Driven Decision Making**: Every functionality decision made through AI completions
- **Multi-Modal Input Processing**: Support for text, audio, video, and file inputs
- **Extensible Tool System**: Modular tools that the AI can invoke to perform actions
- **Real-time Streaming**: Character-by-character streaming responses for immediate feedback

## Features

### ✅ Current Features (Phase 1 Complete)

- **Intelligent Chat Interface**: Real-time streaming chat with AI agent
- **Anthropic Claude Integration**: Seamless API integration with proper authentication
- **Advanced Tool System**: File operations (read/write/create/list directories)
- **Multi-turn Conversations**: Context retention across conversation sessions
- **Real-time Streaming UI**: Character-by-character display with visual feedback
- **Comprehensive Error Handling**: Robust error management and logging
- **Extensive Test Coverage**: 72 tests covering unit, integration, performance, and security

### 🚧 In Development (Phase 2)

- **Audio Input Processing**: Speech-to-text using macOS Speech framework
- **File Upload & Processing**: Drag-and-drop file handling with content analysis
- **Camera Integration**: Real-time video capture and frame analysis
- **Unified Input Pipeline**: Seamless processing of all input modalities

### 🔮 Planned Features (Phase 3-4)

- **Plugin Architecture**: Third-party extensibility through secure plugins
- **Advanced Context Management**: Intelligent context window optimization
- **Tool Chaining**: Automated workflow creation and execution
- **Performance Optimization**: Caching and streaming enhancements
- **Security Hardening**: Advanced sandboxing and permission management

## Architecture

Quartex follows a modular, layered architecture designed for maintainability and extensibility:

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

### Core Components

- **AIAgent**: Central orchestrator managing all AI interactions and tool execution
- **LLMClient**: Handles communication with Anthropic Claude API with streaming support
- **ToolSystem**: Extensible registry of tools the AI can invoke
- **InputProcessing**: Multi-modal input handling and preprocessing
- **ConversationManager**: Context and chat history management

## Installation

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Anthropic API key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/artpar/quartex.git
   cd quartex
   ```

2. **Configure API access**
   ```bash
   cp config.json.example config.json
   # Edit config.json and add your Anthropic API key
   ```

3. **Build the application**
   ```bash
   make
   ```

4. **Run the application**
   ```bash
   make run
   ```

### Configuration

Create a `config.json` file based on the provided example:

```json
{
  "llm": {
    "provider": "anthropic",
    "apiKey": "your-anthropic-api-key",
    "model": "claude-3-sonnet-20240229",
    "endpoint": "https://api.anthropic.com/v1/messages"
  },
  "features": {
    "streaming": true,
    "audioInput": false,
    "fileProcessing": true
  }
}
```

## Usage

### Basic Chat Interaction

1. Launch Quartex
2. Type your request in natural language
3. Watch as the AI agent processes your input and executes appropriate actions
4. View real-time streaming responses with visual feedback

### Example Interactions

**File Operations:**
```
User: "Create a new file called notes.txt with today's meeting agenda"
AI: I'll create that file for you with a meeting agenda template.
```

**System Information:**
```
User: "What files are in my Documents folder?"
AI: Let me check your Documents folder and list the contents for you.
```

**Complex Tasks:**
```
User: "Analyze the CSV file I uploaded and create a summary report"
AI: I'll process your CSV file, analyze the data, and generate a comprehensive summary.
```

## Development

### Project Structure

```
/
├── Core/               # Core AI and tool system
│   ├── AIAgent/       # Central AI orchestration
│   ├── InputProcessing/ # Multi-modal input handling
│   ├── ToolSystem/    # Extensible tool framework
│   └── Extensions/    # Plugin and security management
├── UI/                # User interface components
│   ├── Components/    # Reusable UI components
│   ├── Windows/       # Application windows
│   └── ViewModels/    # MVVM view models
├── Services/          # System services
├── Models/            # Data models
├── Utils/             # Utility classes
└── Resources/         # Assets and configurations
```

### Building and Testing

**Build the application:**
```bash
make                    # Build release version
make debug             # Build debug version
make clean             # Clean build artifacts
```

**Run tests:**
```bash
make test              # Run all tests
make test-unit         # Run unit tests only
make test-integration  # Run integration tests
make test-ui           # Run UI tests
```

**Development workflow:**
```bash
make run               # Build and run
make install           # Install to /Applications
make package          # Create distribution package
```

### Code Style and Guidelines

- Follow Swift naming conventions and best practices
- Use async/await for asynchronous operations
- Implement proper error handling with Result types
- Write comprehensive tests for new features
- Use dependency injection for testability

### Adding New Tools

1. Create a new tool class implementing the `Tool` protocol
2. Register the tool in `ToolRegistry.swift`
3. Add appropriate security permissions
4. Write comprehensive tests

Example tool implementation:
```swift
struct CustomTool: Tool {
    let name = "custom_action"
    let description = "Performs a custom action"
    
    func execute(parameters: [String: Any]) async -> ToolResult {
        // Implementation here
    }
}
```

## Testing

Quartex includes comprehensive test coverage across multiple dimensions:

- **Unit Tests**: Core logic and individual components
- **Integration Tests**: AI agent interactions and tool execution
- **Performance Tests**: Streaming performance and memory usage
- **Security Tests**: Permission validation and sandboxing
- **UI Tests**: User interface workflows and interactions

Current test statistics: **72 tests, 0 failures**

## Contributing

We welcome contributions to Quartex! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Write comprehensive tests** for new functionality
3. **Follow the code style guidelines** outlined above
4. **Update documentation** as needed
5. **Submit a pull request** with a clear description

### Development Setup

1. Read through `CLAUDE.md` for architectural context
2. Check `TODO.md` for current development priorities
3. Set up your development environment following the installation guide
4. Run the test suite to ensure everything works

### Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include detailed reproduction steps for bugs
- Provide system information (macOS version, hardware specs)

## Security

Quartex implements multiple layers of security:

- **API Key Protection**: Secure storage in macOS Keychain
- **Tool Sandboxing**: Isolated execution of tool operations
- **Permission Management**: Granular control over system access
- **Input Validation**: Comprehensive validation of all user inputs

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Swift and AppKit for native macOS experience
- Powered by Anthropic Claude for intelligent AI interactions
- Inspired by the vision of AI-first computing interfaces

## Roadmap

### Short Term (Q1 2024)
- Complete Phase 2: Multi-modal input processing
- Audio input with Speech framework integration
- Enhanced file processing capabilities

### Medium Term (Q2-Q3 2024)
- Plugin architecture implementation
- Advanced context management
- Tool chaining and workflow automation

### Long Term (Q4 2024 and beyond)
- Performance optimization and caching
- Advanced UI customization
- Enterprise features and deployment

---

**Quartex** - Transforming how we interact with computers through AI-powered natural language interfaces.

For more information, visit our [documentation](docs/) or check out the [development guide](CLAUDE.md).