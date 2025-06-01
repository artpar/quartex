import Foundation

class Configuration {
    static let shared = Configuration()
    
    private var config: AppConfig
    private let logger = Logger.shared
    
    private init() {
        self.config = Configuration.loadConfig()
    }
    
    var apiKey: String { config.anthropic_api_key }
    var llmEndpoint: String { config.llm_endpoint }
    var model: String { config.model }
    var maxTokens: Int { config.max_tokens }
    var streamEnabled: Bool { config.stream }
    
    private static func loadConfig() -> AppConfig {
        guard let configPath = Bundle.main.path(forResource: "config", ofType: "json"),
              let configData = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let config = try? JSONDecoder().decode(AppConfig.self, from: configData) else {
            
            let fallbackConfigPath = "./config.json"
            if let fallbackData = try? Data(contentsOf: URL(fileURLWithPath: fallbackConfigPath)),
               let fallbackConfig = try? JSONDecoder().decode(AppConfig.self, from: fallbackData) {
                return fallbackConfig
            }
            
            return AppConfig(
                anthropic_api_key: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "",
                llm_endpoint: "https://api.anthropic.com/v1/messages",
                model: "claude-3-sonnet-20240229",
                max_tokens: 4000,
                stream: true
            )
        }
        return config
    }
    
    func updateConfig(_ newConfig: AppConfig) {
        self.config = newConfig
        logger.info("Configuration updated")
    }
    
    func validateConfiguration() -> Bool {
        guard !apiKey.isEmpty else {
            logger.error("API key is missing")
            return false
        }
        
        guard URL(string: llmEndpoint) != nil else {
            logger.error("Invalid LLM endpoint URL")
            return false
        }
        
        return true
    }
}