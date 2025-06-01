// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Quartex",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "Quartex",
            targets: ["Quartex"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "Quartex",
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
            name: "QuartexTests",
            dependencies: ["Quartex"],
            path: "Tests"
        ),
    ]
)