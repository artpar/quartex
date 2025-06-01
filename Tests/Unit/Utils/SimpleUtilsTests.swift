import XCTest
import Foundation
@testable import AIAgent

class SimpleUtilsTests: XCTestCase {
    
    func testConstants() {
        // Test our Constants are properly defined
        XCTAssertFalse(Constants.appName.isEmpty)
        XCTAssertFalse(Constants.appVersion.isEmpty)
        XCTAssertGreaterThan(Constants.windowDefaultWidth, 0)
        XCTAssertGreaterThan(Constants.windowDefaultHeight, 0)
        XCTAssertGreaterThan(Constants.defaultMaxTokens, 0)
        XCTAssertFalse(Constants.defaultModel.isEmpty)
    }
    
    func testErrorTypes() {
        let noAPIKeyError = AIAgentError.noAPIKey
        XCTAssertNotNil(noAPIKeyError.errorDescription)
        
        let networkError = AIAgentError.networkError(URLError(.notConnectedToInternet))
        XCTAssertNotNil(networkError.errorDescription)
        
        let fileError = AIAgentError.fileOperationFailed("test")
        XCTAssertTrue(fileError.errorDescription?.contains("test") ?? false)
    }
    
    func testStringExtensions() {
        let testString = "Hello World"
        XCTAssertTrue(testString.isNotEmpty)
        
        let emptyString = ""
        XCTAssertFalse(emptyString.isNotEmpty)
        
        let longString = "This is a very long string that should be truncated"
        let truncated = longString.truncated(to: 10)
        XCTAssertEqual(truncated.count, 13) // 10 + "..." = 13
        
        let stringWithSpaces = "  Hello World  "
        let sanitized = stringWithSpaces.sanitized()
        XCTAssertEqual(sanitized, "Hello World")
    }
    
    func testDataExtensions() {
        let testData = "Hello World".data(using: .utf8)!
        let sizeString = testData.humanReadableSize
        XCTAssertFalse(sizeString.isEmpty)
        XCTAssertTrue(sizeString.contains("B") || sizeString.contains("bytes"))
    }
    
    func testDateExtensions() {
        let now = Date()
        let timeAgo = now.timeAgo
        XCTAssertFalse(timeAgo.isEmpty)
        
        let timestamp = now.chatTimestamp
        XCTAssertFalse(timestamp.isEmpty)
    }
    
    func testResultExtensions() {
        let successResult: Result<String, Error> = .success("test")
        XCTAssertTrue(successResult.isSuccess)
        XCTAssertFalse(successResult.isFailure)
        
        let failureResult: Result<String, Error> = .failure(AIAgentError.noData)
        XCTAssertFalse(failureResult.isSuccess)
        XCTAssertTrue(failureResult.isFailure)
    }
}