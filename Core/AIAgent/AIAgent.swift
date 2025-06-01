import Foundation

class AIAgent: ObservableObject {
    private let llmClient: LLMClient
    private var tools: [String: Tool] = [:]
    private let logger = Logger.shared
    
    @Published var currentConversation = Conversation()
    @Published var isProcessing = false
    @Published var streamingResponse = ""
    
    private let systemPrompt = """
    You are an AI assistant integrated into a macOS application. You can help users with various tasks by:
    
    1. Answering questions and providing information
    2. Executing system operations through available tools
    3. Managing files and directories
    4. Automating workflows
    
    Available tools:
    - file_operations: Read, write, create, delete files and directories
    
    When a user requests an action that requires tool usage, respond with a clear explanation of what you'll do, then execute the appropriate tool.
    
    Be helpful, concise, and always explain what actions you're taking.
    """
    
    init() {
        self.llmClient = LLMClient()
        setupTools()
        setupSystemMessage()
    }
    
    private func setupTools() {
        let fileOperationsTool = FileOperationsTool()
        tools[fileOperationsTool.name] = fileOperationsTool
    }
    
    private func setupSystemMessage() {
        currentConversation.addMessage(LLMMessage(role: "system", content: systemPrompt))
    }
    
    func processUserInput(_ input: String, streamingCallback: ((String) -> Void)? = nil) async {
        logger.debug("Processing user input: \(input)")
        DispatchQueue.main.async {
            self.isProcessing = true
            self.streamingResponse = ""
        }
        
        currentConversation.addUserMessage(input)
        
        do {
            logger.debug("About to send to LLM with \(currentConversation.messages.count) messages")
            let response = try await sendToLLM(streamingCallback: streamingCallback)
            logger.debug("Received LLM response: \(String(response.prefix(100)))...")
            
            DispatchQueue.main.async {
                self.currentConversation.addAssistantMessage(response)
                self.isProcessing = false
            }
            
            await processToolRequests(in: response)
            
        } catch {
            logger.error("Error in processUserInput: \(error.localizedDescription)")
            DispatchQueue.main.async {
                let errorMessage = "Error: \(error.localizedDescription)"
                self.currentConversation.addAssistantMessage(errorMessage)
                self.isProcessing = false
            }
        }
    }
    
    private func sendToLLM(streamingCallback: ((String) -> Void)? = nil) async throws -> String {
        print("🚀 AIAgent.sendToLLM called")
        logger.debug("sendToLLM called - about to call llmClient.sendMessage")
        return try await withCheckedThrowingContinuation { continuation in
            llmClient.sendMessage(messages: currentConversation.messages, streamingCallback: streamingCallback) { result in
                switch result {
                case .success(let response):
                    self.logger.debug("LLM success: \(String(response.prefix(100)))...")
                case .failure(let error):
                    self.logger.error("LLM error: \(error.localizedDescription)")
                }
                continuation.resume(with: result)
            }
        }
    }
    
    func processToolRequests(in response: String) async {
        let toolPattern = #"@(\w+)\((.*?)\)"#
        let regex = try! NSRegularExpression(pattern: toolPattern, options: [])
        let matches = regex.matches(in: response, options: [], range: NSRange(location: 0, length: response.utf16.count))
        
        for match in matches {
            if let toolNameRange = Range(match.range(at: 1), in: response),
               let parametersRange = Range(match.range(at: 2), in: response) {
                
                let toolName = String(response[toolNameRange])
                let parametersString = String(response[parametersRange])
                
                await executeTool(name: toolName, parametersString: parametersString)
            }
        }
    }
    
    private func executeTool(name: String, parametersString: String) async {
        guard let tool = tools[name] else {
            let errorMessage = "Tool '\(name)' not found"
            DispatchQueue.main.async {
                self.currentConversation.addAssistantMessage("Error: \(errorMessage)")
            }
            return
        }
        
        let parameters = parseParameters(parametersString)
        let result = await tool.execute(parameters: parameters)
        
        DispatchQueue.main.async {
            if result.success {
                self.currentConversation.addAssistantMessage("Tool execution result: \(result.output)")
            } else {
                self.currentConversation.addAssistantMessage("Tool execution failed: \(result.error ?? "Unknown error")")
            }
        }
    }
    
    func parseParameters(_ parametersString: String) -> [String: Any] {
        let components = parametersString.components(separatedBy: ",")
        var parameters: [String: Any] = [:]
        
        for component in components {
            let keyValue = component.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
                let value = keyValue[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
                parameters[key] = value
            }
        }
        
        return parameters
    }
    
    func clearConversation() {
        currentConversation = Conversation()
        setupSystemMessage()
    }
}

struct FileOperationsTool: Tool {
    let name = "file_operations"
    let description = "Perform file system operations: read, write, create, delete files and directories"
    
    func execute(parameters: [String: Any]) async -> ToolResult {
        guard let operation = parameters["operation"] as? String else {
            return ToolResult(success: false, output: "", error: "Missing 'operation' parameter")
        }
        
        switch operation {
        case "read":
            return await readFile(parameters: parameters)
        case "write":
            return await writeFile(parameters: parameters)
        case "create_directory":
            return await createDirectory(parameters: parameters)
        case "list":
            return await listDirectory(parameters: parameters)
        default:
            return ToolResult(success: false, output: "", error: "Unknown operation: \(operation)")
        }
    }
    
    private func readFile(parameters: [String: Any]) async -> ToolResult {
        guard let path = parameters["path"] as? String else {
            return ToolResult(success: false, output: "", error: "Missing 'path' parameter")
        }
        
        do {
            let content = try String(contentsOfFile: path)
            return ToolResult(success: true, output: content, error: nil)
        } catch {
            return ToolResult(success: false, output: "", error: error.localizedDescription)
        }
    }
    
    private func writeFile(parameters: [String: Any]) async -> ToolResult {
        guard let path = parameters["path"] as? String,
              let content = parameters["content"] as? String else {
            return ToolResult(success: false, output: "", error: "Missing 'path' or 'content' parameter")
        }
        
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            return ToolResult(success: true, output: "File written successfully", error: nil)
        } catch {
            return ToolResult(success: false, output: "", error: error.localizedDescription)
        }
    }
    
    private func createDirectory(parameters: [String: Any]) async -> ToolResult {
        guard let path = parameters["path"] as? String else {
            return ToolResult(success: false, output: "", error: "Missing 'path' parameter")
        }
        
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return ToolResult(success: true, output: "Directory created successfully", error: nil)
        } catch {
            return ToolResult(success: false, output: "", error: error.localizedDescription)
        }
    }
    
    private func listDirectory(parameters: [String: Any]) async -> ToolResult {
        guard let path = parameters["path"] as? String else {
            return ToolResult(success: false, output: "", error: "Missing 'path' parameter")
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            return ToolResult(success: true, output: contents.joined(separator: "\n"), error: nil)
        } catch {
            return ToolResult(success: false, output: "", error: error.localizedDescription)
        }
    }
}