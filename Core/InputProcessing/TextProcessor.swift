import Foundation
import NaturalLanguage

class TextProcessor {
    
    // MARK: - Text Processing
    
    func processInputEvent(_ event: InputEvent) async throws -> String {
        guard event.type == .text else {
            throw TextProcessorError.invalidInputType
        }
        
        guard let text = event.metadata["text"] as? String else {
            // Try to extract text from content data
            guard let extractedText = String(data: event.content, encoding: .utf8) else {
                throw TextProcessorError.unableToExtractText
            }
            return extractedText
        }
        
        return text
    }
    
    func processText(_ text: String) async -> ProcessedText {
        let cleanedText = cleanText(text)
        let language = detectLanguage(cleanedText)
        let sentiment = analyzeSentiment(cleanedText)
        let entities = extractEntities(cleanedText)
        let wordCount = countWords(cleanedText)
        
        return ProcessedText(
            originalText: text,
            cleanedText: cleanedText,
            language: language,
            sentiment: sentiment,
            entities: entities,
            wordCount: wordCount
        )
    }
    
    // MARK: - Text Cleaning
    
    private func cleanText(_ text: String) -> String {
        var cleaned = text
        
        // Remove excessive whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    // MARK: - Language Detection
    
    private func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return nil
        }
        
        return language.rawValue
    }
    
    // MARK: - Sentiment Analysis
    
    private func analyzeSentiment(_ text: String) -> SentimentScore {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let sentimentScore = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        
        if let score = sentimentScore, let doubleScore = Double(score.rawValue) {
            return SentimentScore(
                score: doubleScore,
                classification: classifySentiment(doubleScore)
            )
        }
        
        return SentimentScore(score: 0.0, classification: .neutral)
    }
    
    private func classifySentiment(_ score: Double) -> SentimentClassification {
        if score > 0.1 {
            return .positive
        } else if score < -0.1 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    // MARK: - Entity Extraction
    
    private func extractEntities(_ text: String) -> [TextEntity] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [TextEntity] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let entity = String(text[tokenRange])
                let entityType = mapEntityType(tag)
                entities.append(TextEntity(text: entity, type: entityType, range: tokenRange))
            }
            return true
        }
        
        return entities
    }
    
    private func mapEntityType(_ tag: NLTag) -> EntityType {
        switch tag {
        case .personalName:
            return .person
        case .placeName:
            return .location
        case .organizationName:
            return .organization
        default:
            return .other
        }
    }
    
    // MARK: - Text Statistics
    
    private func countWords(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    func getTextStatistics(_ text: String) -> TextStatistics {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let sentences = text.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }
        let characters = text.count
        let charactersNoSpaces = text.replacingOccurrences(of: " ", with: "").count
        
        return TextStatistics(
            characterCount: characters,
            characterCountNoSpaces: charactersNoSpaces,
            wordCount: words.count,
            sentenceCount: sentences.count,
            averageWordsPerSentence: sentences.isEmpty ? 0 : Double(words.count) / Double(sentences.count)
        )
    }
    
    // MARK: - Text Validation
    
    func validateText(_ text: String) -> TextValidationResult {
        var issues: [TextValidationIssue] = []
        
        // Check length
        if text.isEmpty {
            issues.append(.empty)
        } else if text.count > 10000 {
            issues.append(.tooLong)
        }
        
        // Check for common issues
        if text.trimmingCharacters(in: .whitespacesAndNewlines) != text {
            issues.append(.excessiveWhitespace)
        }
        
        if text.contains("\u{FFFD}") { // Unicode replacement character
            issues.append(.encodingIssues)
        }
        
        return TextValidationResult(isValid: issues.isEmpty, issues: issues)
    }
}

// MARK: - Supporting Types

struct ProcessedText {
    let originalText: String
    let cleanedText: String
    let language: String?
    let sentiment: SentimentScore
    let entities: [TextEntity]
    let wordCount: Int
}

struct SentimentScore {
    let score: Double // -1.0 to 1.0
    let classification: SentimentClassification
}

enum SentimentClassification {
    case positive
    case negative
    case neutral
}

struct TextEntity {
    let text: String
    let type: EntityType
    let range: Range<String.Index>
}

enum EntityType {
    case person
    case location
    case organization
    case other
}

struct TextStatistics {
    let characterCount: Int
    let characterCountNoSpaces: Int
    let wordCount: Int
    let sentenceCount: Int
    let averageWordsPerSentence: Double
}

struct TextValidationResult {
    let isValid: Bool
    let issues: [TextValidationIssue]
}

enum TextValidationIssue {
    case empty
    case tooLong
    case excessiveWhitespace
    case encodingIssues
}

// MARK: - Error Types

enum TextProcessorError: Error, LocalizedError {
    case invalidInputType
    case unableToExtractText
    case textTooLong
    case invalidEncoding
    
    var errorDescription: String? {
        switch self {
        case .invalidInputType:
            return "Input type is not text"
        case .unableToExtractText:
            return "Unable to extract text from input data"
        case .textTooLong:
            return "Text is too long to process"
        case .invalidEncoding:
            return "Text encoding is invalid"
        }
    }
}