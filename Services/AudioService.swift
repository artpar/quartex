import Foundation
import AVFoundation

class AudioService {
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    // MARK: - Recording Management
    
    func startRecording() async throws -> URL {
        // Request permissions
        let hasPermission = await requestRecordingPermission()
        guard hasPermission else {
            throw AudioServiceError.permissionDenied
        }
        
        // Configure audio session
        try configureAudioSession()
        
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording-\(Date().timeIntervalSince1970).m4a")
        recordingURL = audioFilename
        
        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        
        guard audioRecorder?.record() == true else {
            throw AudioServiceError.recordingFailed
        }
        
        Logger.shared.info("Started audio recording to: \(audioFilename)")
        return audioFilename
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        
        defer {
            do {
                try audioSession.setActive(false)
            } catch {
                Logger.shared.error("Failed to deactivate audio session: \(error)")
            }
        }
        
        guard let url = recordingURL else {
            Logger.shared.error("No recording URL available")
            return nil
        }
        
        Logger.shared.info("Stopped audio recording")
        return url
    }
    
    func isRecording() -> Bool {
        return audioRecorder?.isRecording ?? false
    }
    
    // MARK: - Playback
    
    func playAudio(from url: URL) async throws {
        let audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
        // Wait for playback to complete
        while audioPlayer.isPlaying {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    func getAudioLevel() -> Float {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return 0.0
        }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10, averagePower / 20)
        return normalizedLevel
    }
    
    // MARK: - Permission Management
    
    private func requestRecordingPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Configuration
    
    private func configureAudioSession() throws {
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
    }
    
    // MARK: - File Management
    
    func deleteRecording(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
        Logger.shared.info("Deleted audio recording: \(url)")
    }
    
    func getRecordingDuration(at url: URL) throws -> TimeInterval {
        let audioFile = try AVAudioFile(forReading: url)
        let sampleRate = audioFile.processingFormat.sampleRate
        let frameCount = audioFile.length
        return Double(frameCount) / sampleRate
    }
    
    func convertToInputEvent(audioURL: URL, metadata: [String: Any] = [:]) throws -> InputEvent {
        let audioData = try Data(contentsOf: audioURL)
        var eventMetadata = metadata
        eventMetadata["duration"] = try getRecordingDuration(at: audioURL)
        eventMetadata["url"] = audioURL.absoluteString
        
        return InputEvent(type: .audio, content: audioData, metadata: eventMetadata)
    }
}

// MARK: - Error Types

enum AudioServiceError: Error, LocalizedError {
    case permissionDenied
    case recordingFailed
    case playbackFailed
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission was denied"
        case .recordingFailed:
            return "Failed to start audio recording"
        case .playbackFailed:
            return "Failed to play audio file"
        case .fileNotFound:
            return "Audio file not found"
        }
    }
}