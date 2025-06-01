import Foundation

struct AppConfig: Codable {
    let anthropic_api_key: String
    let llm_endpoint: String
    let model: String
    let max_tokens: Int
    let stream: Bool
}

class LLMClient: ObservableObject {
    private let config = Configuration.shared
    private let session = URLSession.shared
    private let logger = Logger.shared
    
    @Published var isStreaming = false
    @Published var currentResponse = ""
    
    init() {
        logger.info("LLMClient initialized")
    }
    
    func sendMessage(messages: [LLMMessage], streamingCallback: ((String) -> Void)? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        print("🔥 LLMClient.sendMessage called with \(messages.count) messages")
        logger.debug("Starting LLM request with \(messages.count) messages")
        
        guard !config.apiKey.isEmpty else {
            logger.error("API key is empty")
            completion(.failure(AIAgentError.noAPIKey))
            return
        }
        
        logger.debug("API Key present: \(config.apiKey.prefix(10))...")
        logger.debug("Endpoint: \(config.llmEndpoint)")
        logger.debug("Model: \(config.model)")
        logger.debug("Stream enabled: \(config.streamEnabled)")
        
        // Separate system messages from user/assistant messages for Anthropic API
        let systemMessages = messages.filter { $0.role == "system" }
        let conversationMessages = messages.filter { $0.role != "system" }
        
        var requestBody: [String: Any] = [
            "model": config.model,
            "messages": conversationMessages.map { ["role": $0.role, "content": $0.content] },
            "stream": config.streamEnabled,
            "max_tokens": config.maxTokens
        ]
        
        // Add system parameter if we have system messages
        if let systemMessage = systemMessages.first {
            requestBody["system"] = systemMessage.content
        }
        
        var urlRequest = URLRequest(url: URL(string: config.llmEndpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Constants.apiVersion, forHTTPHeaderField: "anthropic-version")
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            logger.debug("Request body created successfully")
            if let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8) {
                logger.debug("Request body: \(bodyString)")
                print("📤 Request body: \(bodyString)")
            }
        } catch {
            logger.error("Failed to create request body: \(error)")
            completion(.failure(error))
            return
        }
        
        if config.streamEnabled {
            streamResponse(request: urlRequest, streamingCallback: streamingCallback, completion: completion)
        } else {
            regularResponse(request: urlRequest, completion: completion)
        }
    }
    
    private func streamResponse(request: URLRequest, streamingCallback: ((String) -> Void)? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        isStreaming = true
        currentResponse = ""
        
        logger.debug("Starting streaming request...")
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isStreaming = false
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                self?.logger.debug("HTTP Status: \(httpResponse.statusCode)")
                self?.logger.debug("HTTP Headers: \(httpResponse.allHeaderFields)")
                print("🌐 HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("❌ HTTP Error - Status: \(httpResponse.statusCode)")
                    if let data = data, let errorString = String(data: data, encoding: .utf8) {
                        print("❌ Error Response: \(errorString)")
                    }
                }
            }
            
            if let error = error {
                self?.logger.error("Network error: \(error.localizedDescription)")
                print("🚨 Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                self?.logger.error("No data received from server")
                DispatchQueue.main.async {
                    completion(.failure(AIAgentError.noData))
                }
                return
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? ""
            self?.logger.debug("Raw response (first 500 chars): \(String(responseString.prefix(500)))")
            let lines = responseString.components(separatedBy: "\n")
            
            var fullResponse = ""
            
            for line in lines {
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" { break }
                    
                    if let jsonData = jsonString.data(using: .utf8),
                       let streamResponse = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        // Handle content delta for streaming - Anthropic format
                        if let type = streamResponse["type"] as? String {
                            if type == "content_block_delta",
                               let delta = streamResponse["delta"] as? [String: Any],
                               let text = delta["text"] as? String {
                                fullResponse += text
                                DispatchQueue.main.async {
                                    self?.currentResponse = fullResponse
                                    streamingCallback?(fullResponse)
                                }
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(fullResponse))
            }
        }
        
        task.resume()
    }
    
    private func regularResponse(request: URLRequest, completion: @escaping (Result<String, Error>) -> Void) {
        logger.debug("Starting regular request...")
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                self?.logger.debug("HTTP Status: \(httpResponse.statusCode)")
                self?.logger.debug("HTTP Headers: \(httpResponse.allHeaderFields)")
                print("🌐 HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("❌ HTTP Error - Status: \(httpResponse.statusCode)")
                    if let data = data, let errorString = String(data: data, encoding: .utf8) {
                        print("❌ Error Response: \(errorString)")
                    }
                }
            }
            
            if let error = error {
                self?.logger.error("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                self?.logger.error("No data received from server")
                completion(.failure(AIAgentError.noData))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                self?.logger.debug("Raw response: \(responseString)")
                print("📥 Raw response: \(responseString)")
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let content = jsonResponse?["content"] as? [[String: Any]],
                   let firstContent = content.first,
                   let text = firstContent["text"] as? String {
                    self?.logger.debug("Successfully extracted text response: \(String(text.prefix(100)))...")
                    completion(.success(text))
                } else {
                    self?.logger.error("Failed to parse response structure")
                    if let jsonResponse = jsonResponse {
                        self?.logger.debug("Response structure: \(jsonResponse)")
                    }
                    completion(.failure(AIAgentError.invalidResponse))
                }
            } catch {
                self?.logger.error("Failed to decode LLM response: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}