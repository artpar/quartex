import Foundation

protocol Tool {
    var name: String { get }
    var description: String { get }
    func execute(parameters: [String: Any]) async -> ToolResult
}

struct ToolResult {
    let success: Bool
    let output: String
    let error: String?
}