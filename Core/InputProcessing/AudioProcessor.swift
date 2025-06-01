import Foundation
import Speech
import AVFoundation

class AudioProcessor {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init(locale: Locale = Locale.current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        self.speechRecognizer?.delegate = self
    }
    
    // MARK: - Permission Management
    
    func requestPermissions() async -> Bool {
        let speechAuthStatus = await requestSpeechRecognitionPermission()
        let microphoneAuthStatus = await requestMicrophonePermission()
        
        return speechAuthStatus && microphoneAuthStatus
    }
    
    private func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                continuation.resume(returning: authStatus == .authorized)
            }
        }
    }
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Recording and Recognition
    
    func startRecording(onResult: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            onError(AudioProcessorError.speechRecognizerUnavailable)
            return
        }
        
        // Cancel any previous task
        stopRecording()
        
        // Configure audio session
        do {
            try configureAudioSession()
        } catch {
            onError(error)
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            onError(AudioProcessorError.recognitionRequestCreationFailed)
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                onResult(transcribedText)
            }
            
            if let error = error {
                onError(error)
                self.stopRecording()
            }
        }
        
        // Configure audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
        } catch {
            onError(error)
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    // MARK: - Audio File Processing
    
    func processAudioFile(at url: URL) async throws -> String {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw AudioProcessorError.speechRecognizerUnavailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return try await withCheckedThrowingContinuation { continuation in
            speechRecognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    func processInputEvent(_ event: InputEvent) async throws -> String {
        guard event.type == .audio else {
            throw AudioProcessorError.invalidInputType
        }
        
        // Create temporary file from audio data
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        try event.content.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        return try await processAudioFile(at: tempURL)
    }
    
    // MARK: - Configuration
    
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension AudioProcessor: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle availability changes
        Logger.shared.info("Speech recognizer availability changed: \(available)")
    }
}

// MARK: - Error Types

enum AudioProcessorError: Error, LocalizedError {
    case speechRecognizerUnavailable
    case recognitionRequestCreationFailed
    case invalidInputType
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .speechRecognizerUnavailable:
            return "Speech recognizer is not available"
        case .recognitionRequestCreationFailed:
            return "Failed to create speech recognition request"
        case .invalidInputType:
            return "Input type is not audio"
        case .permissionDenied:
            return "Permission denied for speech recognition or microphone access"
        }
    }
}