import XCTest
@testable import AIAgent
import Foundation

class ToolIntegrationTests: XCTestCase {
    
    var tempDirectory: URL!
    var testAgent: AIAgent!
    
    override func setUp() {
        super.setUp()
        
        // Create temporary directory for testing
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AIAgentTests_\(UUID().uuidString)")
        
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        testAgent = AIAgent()
    }
    
    override func tearDown() {
        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        
        testAgent = nil
        super.tearDown()
    }
    
    // MARK: - File Operations Integration Tests
    
    func testFileReadOperation() async {
        // Create a test file
        let testFile = tempDirectory.appendingPathComponent("test_read.txt")
        let testContent = "This is test content for reading."
        try! testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        // Test file read through tool
        let fileOperationsTool = FileOperationsTool()
        let parameters = [
            "operation": "read",
            "path": testFile.path
        ]
        
        let result = await fileOperationsTool.execute(parameters: parameters)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output, testContent)
        XCTAssertNil(result.error)
    }
    
    func testFileWriteOperation() async {
        let testFile = tempDirectory.appendingPathComponent("test_write.txt")
        let testContent = "This content was written by the tool."
        
        let fileOperationsTool = FileOperationsTool()
        let parameters = [
            "operation": "write",
            "path": testFile.path,
            "content": testContent
        ]
        
        let result = await fileOperationsTool.execute(parameters: parameters)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output, "File written successfully")
        XCTAssertNil(result.error)
        
        // Verify file was actually written
        let readContent = try! String(contentsOf: testFile)
        XCTAssertEqual(readContent, testContent)
    }
    
    func testDirectoryCreation() async {
        let newDirectory = tempDirectory.appendingPathComponent("new_test_directory")
        
        let fileOperationsTool = FileOperationsTool()
        let parameters = [
            "operation": "create_directory",
            "path": newDirectory.path
        ]
        
        let result = await fileOperationsTool.execute(parameters: parameters)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output, "Directory created successfully")
        XCTAssertNil(result.error)
        
        // Verify directory was created
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: newDirectory.path, isDirectory: &isDirectory)
        XCTAssertTrue(exists)
        XCTAssertTrue(isDirectory.boolValue)
    }
    
    func testDirectoryListing() async {
        // Create some test files
        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = tempDirectory.appendingPathComponent("file2.txt")
        try! "Content 1".write(to: file1, atomically: true, encoding: .utf8)
        try! "Content 2".write(to: file2, atomically: true, encoding: .utf8)
        
        let fileOperationsTool = FileOperationsTool()
        let parameters = [
            "operation": "list",
            "path": tempDirectory.path
        ]
        
        let result = await fileOperationsTool.execute(parameters: parameters)
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("file1.txt"))
        XCTAssertTrue(result.output.contains("file2.txt"))
        XCTAssertNil(result.error)
    }
    
    func testFileOperationErrors() async {
        let fileOperationsTool = FileOperationsTool()
        
        // Test reading non-existent file
        let readResult = await fileOperationsTool.execute(parameters: [
            "operation": "read",
            "path": "/nonexistent/file.txt"
        ])
        
        XCTAssertFalse(readResult.success)
        XCTAssertNotNil(readResult.error)
        
        // Test invalid operation
        let invalidResult = await fileOperationsTool.execute(parameters: [
            "operation": "invalid_operation",
            "path": "/some/path"
        ])
        
        XCTAssertFalse(invalidResult.success)
        XCTAssertEqual(invalidResult.error, "Unknown operation: invalid_operation")
        
        // Test missing parameters
        let missingParamResult = await fileOperationsTool.execute(parameters: [:])
        
        XCTAssertFalse(missingParamResult.success)
        XCTAssertEqual(missingParamResult.error, "Missing 'operation' parameter")
    }
    
    // MARK: - Tool Chain Integration Tests
    
    func testToolChainExecution() async {
        // Create a file, then read it back - testing tool chain
        let testFile = tempDirectory.appendingPathComponent("chain_test.txt")
        let testContent = "This tests tool chaining."
        
        let fileOperationsTool = FileOperationsTool()
        
        // Step 1: Write file
        let writeResult = await fileOperationsTool.execute(parameters: [
            "operation": "write",
            "path": testFile.path,
            "content": testContent
        ])
        
        XCTAssertTrue(writeResult.success)
        
        // Step 2: Read the file back
        let readResult = await fileOperationsTool.execute(parameters: [
            "operation": "read",
            "path": testFile.path
        ])
        
        XCTAssertTrue(readResult.success)
        XCTAssertEqual(readResult.output, testContent)
        
        // Step 3: List directory to verify file exists
        let listResult = await fileOperationsTool.execute(parameters: [
            "operation": "list",
            "path": tempDirectory.path
        ])
        
        XCTAssertTrue(listResult.success)
        XCTAssertTrue(listResult.output.contains("chain_test.txt"))
    }
    
    // MARK: - AI Agent Tool Integration Tests
    
    func testAIAgentToolIntegration() async {
        // This test would require mocking the LLM response to include tool calls
        // For now, we'll test the tool parsing mechanism
        
        let responseWithToolCall = """
        I'll help you create that file. Let me use the file operations tool.
        
        @file_operations(operation: "write", path: "\(tempDirectory.path)/ai_created.txt", content: "Created by AI")
        
        File has been created successfully!
        """
        
        // Test tool pattern matching
        let toolPattern = #"@(\w+)\((.*?)\)"#
        let regex = try! NSRegularExpression(pattern: toolPattern, options: [])
        let matches = regex.matches(in: responseWithToolCall, options: [], range: NSRange(location: 0, length: responseWithToolCall.utf16.count))
        
        XCTAssertEqual(matches.count, 1)
        
        let match = matches[0]
        let toolNameRange = Range(match.range(at: 1), in: responseWithToolCall)!
        let parametersRange = Range(match.range(at: 2), in: responseWithToolCall)!
        
        let toolName = String(responseWithToolCall[toolNameRange])
        let parametersString = String(responseWithToolCall[parametersRange])
        
        XCTAssertEqual(toolName, "file_operations")
        XCTAssertTrue(parametersString.contains("operation: \"write\""))
        XCTAssertTrue(parametersString.contains("ai_created.txt"))
    }
    
    func testParameterParsing() {
        // Test the parameter parsing mechanism from AIAgent
        let testAgent = AIAgent()
        
        let testParameterString = "operation: \"read\", path: \"/tmp/test.txt\""
        let parsed = testAgent.parseParameters(testParameterString)
        
        XCTAssertEqual(parsed["operation"] as? String, "read")
        XCTAssertEqual(parsed["path"] as? String, "/tmp/test.txt")
    }
    
    // MARK: - Performance Tests for Tool Operations
    
    func testToolPerformanceWithLargeFiles() async {
        // Create a large test file
        let largeContent = String(repeating: "This is line \(Int.random(in: 1...1000))\n", count: 10000)
        let largeFile = tempDirectory.appendingPathComponent("large_test.txt")
        try! largeContent.write(to: largeFile, atomically: true, encoding: .utf8)
        
        let fileOperationsTool = FileOperationsTool()
        
        // Measure read performance
        let startTime = Date()
        let result = await fileOperationsTool.execute(parameters: [
            "operation": "read",
            "path": largeFile.path
        ])
        let readTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(result.success)
        XCTAssertLessThan(readTime, 2.0) // Should complete within 2 seconds
        XCTAssertEqual(result.output.count, largeContent.count)
    }
    
    func testConcurrentToolExecution() async {
        let fileOperationsTool = FileOperationsTool()
        
        // Create multiple files concurrently
        let tasks = (1...5).map { i in
            Task {
                await fileOperationsTool.execute(parameters: [
                    "operation": "write",
                    "path": tempDirectory.appendingPathComponent("concurrent_\(i).txt").path,
                    "content": "Concurrent file \(i)"
                ])
            }
        }
        
        let results = await withTaskGroup(of: ToolResult.self) { group in
            for task in tasks {
                group.addTask {
                    await task.value
                }
            }
            
            var results: [ToolResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // All operations should succeed
        XCTAssertEqual(results.count, 5)
        for result in results {
            XCTAssertTrue(result.success)
        }
        
        // Verify all files were created
        let listResult = await fileOperationsTool.execute(parameters: [
            "operation": "list",
            "path": tempDirectory.path
        ])
        
        XCTAssertTrue(listResult.success)
        for i in 1...5 {
            XCTAssertTrue(listResult.output.contains("concurrent_\(i).txt"))
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testToolWithEmptyContent() async {
        let fileOperationsTool = FileOperationsTool()
        let emptyFile = tempDirectory.appendingPathComponent("empty.txt")
        
        // Write empty content
        let writeResult = await fileOperationsTool.execute(parameters: [
            "operation": "write",
            "path": emptyFile.path,
            "content": ""
        ])
        
        XCTAssertTrue(writeResult.success)
        
        // Read empty file
        let readResult = await fileOperationsTool.execute(parameters: [
            "operation": "read",
            "path": emptyFile.path
        ])
        
        XCTAssertTrue(readResult.success)
        XCTAssertEqual(readResult.output, "")
    }
    
    func testToolWithSpecialCharacters() async {
        let fileOperationsTool = FileOperationsTool()
        let specialFile = tempDirectory.appendingPathComponent("special_chars.txt")
        let specialContent = "Special characters: áéíóú ñ 中文 🚀 \"quotes\" and 'apostrophes'"
        
        let writeResult = await fileOperationsTool.execute(parameters: [
            "operation": "write",
            "path": specialFile.path,
            "content": specialContent
        ])
        
        XCTAssertTrue(writeResult.success)
        
        let readResult = await fileOperationsTool.execute(parameters: [
            "operation": "read",
            "path": specialFile.path
        ])
        
        XCTAssertTrue(readResult.success)
        XCTAssertEqual(readResult.output, specialContent)
    }
}