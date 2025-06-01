import Foundation

protocol AIPlugin {
    var name: String { get }
    var tools: [Tool] { get }
    func execute(tool: Tool, parameters: [String: Any]) async -> ToolResult
}

struct PluginInfo {
    let name: String
    let version: String
    let description: String
    let author: String
    let tools: [String]
    
    init(name: String, version: String, description: String, author: String, tools: [String]) {
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.tools = tools
    }
}