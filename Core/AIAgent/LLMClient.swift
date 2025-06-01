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
    
    func sendMessage(messages: [LLMMessage], completion: @escaping (Result<String, Error>) -> Void) {
        guard !config.apiKey.isEmpty else {
            completion(.failure(AIAgentError.noAPIKey))
            return
        }
        
        let request = LLMRequest(
            model: config.model,
            messages: messages,
            stream: config.streamEnabled,
            maxTokens: config.maxTokens
        )
        
        var urlRequest = URLRequest(url: URL(string: config.llmEndpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(config.apiKey)", forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Constants.apiVersion, forHTTPHeaderField: "anthropic-version")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        if request.stream {
            streamResponse(request: urlRequest, completion: completion)
        } else {
            regularResponse(request: urlRequest, completion: completion)
        }
    }
    
    private func streamResponse(request: URLRequest, completion: @escaping (Result<String, Error>) -> Void) {
        isStreaming = true
        currentResponse = ""
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isStreaming = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(AIAgentError.noData))
                }
                return
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? ""
            let lines = responseString.components(separatedBy: "\n")
            
            var fullResponse = ""
            
            for line in lines {
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    if jsonString == "[DONE]" { break }
                    
                    if let jsonData = jsonString.data(using: .utf8),
                       let streamResponse = try? JSONDecoder().decode(LLMResponse.self, from: jsonData),
                       let content = streamResponse.delta?.content {
                        fullResponse += content
                        DispatchQueue.main.async {
                            self?.currentResponse = fullResponse
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
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(AIAgentError.noData))
                return
            }
            
            do {
                let llmResponse = try JSONDecoder().decode(LLMResponse.self, from: data)
                let content = llmResponse.choices?.first?.message?.content ?? ""
                completion(.success(content))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}