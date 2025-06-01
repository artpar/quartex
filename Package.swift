// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIAgent",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "AIAgent",
            targets: ["AIAgent"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "AIAgent",
            dependencies: [],
            path: ".",
            sources: [
                "main.swift",
                "AppDelegate.swift",
                "Core/AIAgent/AIAgent.swift",
                "Core/AIAgent/LLMClient.swift",
                "UI/Components/ViewController.swift",
                "UI/Components/StreamingTextView.swift",
                "Models/Message.swift",
                "Models/Conversation.swift",
                "Models/Tool.swift",
                "Models/AIResponse.swift",
                "Models/InputEvent.swift",
                "Models/Plugin.swift",
                "Utils/Logger.swift",
                "Utils/Configuration.swift",
                "Utils/Constants.swift",
                "Utils/ErrorHandling.swift",
                "Utils/Extensions.swift"
            ]
        ),
        .testTarget(
            name: "AIAgentTests",
            dependencies: ["AIAgent"],
            path: "Tests"
        ),
    ]
)