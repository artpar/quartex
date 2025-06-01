import Foundation
import AVFoundation
import CoreImage

class VideoProcessor {
    
    // MARK: - Video Processing
    
    func processInputEvent(_ event: InputEvent) async throws -> String {
        guard event.type == .video else {
            throw VideoProcessorError.invalidInputType
        }
        
        // Create temporary file from video data
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        try event.content.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let metadata = try await analyzeVideo(at: tempURL)
        return createVideoDescription(from: metadata, originalMetadata: event.metadata)
    }
    
    func analyzeVideo(at url: URL) async throws -> VideoMetadata {
        let asset = AVAsset(url: url)
        
        // Load asset properties
        let duration = try await asset.load(.duration)
        let tracks = try await asset.load(.tracks)
        
        var videoTrack: AVAssetTrack?
        var audioTrack: AVAssetTrack?
        
        for track in tracks {
            let mediaType = try await track.load(.mediaType)
            if mediaType == .video && videoTrack == nil {
                videoTrack = track
            } else if mediaType == .audio && audioTrack == nil {
                audioTrack = track
            }
        }
        
        var videoInfo: VideoTrackInfo?
        var audioInfo: AudioTrackInfo?
        
        // Analyze video track
        if let track = videoTrack {
            let naturalSize = try await track.load(.naturalSize)
            let nominalFrameRate = try await track.load(.nominalFrameRate)
            let estimatedDataRate = try await track.load(.estimatedDataRate)
            
            videoInfo = VideoTrackInfo(
                resolution: naturalSize,
                frameRate: nominalFrameRate,
                dataRate: estimatedDataRate
            )
        }
        
        // Analyze audio track
        if let track = audioTrack {
            let estimatedDataRate = try await track.load(.estimatedDataRate)
            
            audioInfo = AudioTrackInfo(
                dataRate: estimatedDataRate
            )
        }
        
        return VideoMetadata(
            duration: CMTimeGetSeconds(duration),
            videoTrack: videoInfo,
            audioTrack: audioInfo,
            fileSize: try getFileSize(at: url)
        )
    }
    
    // MARK: - Frame Extraction
    
    func extractFrames(from url: URL, at times: [TimeInterval]) async throws -> [FrameData] {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        var frames: [FrameData] = []
        
        for time in times {
            do {
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)
                let cgImage = try await imageGenerator.image(at: cmTime).image
                
                let frameData = FrameData(
                    time: time,
                    image: cgImage,
                    size: CGSize(width: cgImage.width, height: cgImage.height)
                )
                frames.append(frameData)
            } catch {
                Logger.shared.error("Failed to extract frame at time \(time): \(error)")
            }
        }
        
        return frames
    }
    
    func extractKeyFrames(from url: URL, maxFrames: Int = 10) async throws -> [FrameData] {
        let metadata = try await analyzeVideo(at: url)
        let duration = metadata.duration
        
        // Calculate evenly distributed time points
        var times: [TimeInterval] = []
        if maxFrames == 1 {
            times.append(duration / 2) // Middle frame
        } else {
            for i in 0..<maxFrames {
                let time = (duration / Double(maxFrames - 1)) * Double(i)
                times.append(min(time, duration - 0.1)) // Ensure we don't go past the end
            }
        }
        
        return try await extractFrames(from: url, at: times)
    }
    
    // MARK: - Video Description Generation
    
    private func createVideoDescription(from metadata: VideoMetadata, originalMetadata: [String: Any]) -> String {
        var description = "Video file"
        
        if let filename = originalMetadata["filename"] as? String {
            description += ": \(filename)"
        }
        
        description += "\n"
        
        // Duration
        let minutes = Int(metadata.duration) / 60
        let seconds = Int(metadata.duration) % 60
        description += "Duration: \(minutes):\(String(format: "%02d", seconds))\n"
        
        // Video track info
        if let videoTrack = metadata.videoTrack {
            description += "Resolution: \(Int(videoTrack.resolution.width))x\(Int(videoTrack.resolution.height))\n"
            description += "Frame Rate: \(String(format: "%.1f", videoTrack.frameRate)) fps\n"
        }
        
        // Audio track info
        if metadata.audioTrack != nil {
            description += "Has audio track\n"
        } else {
            description += "No audio track\n"
        }
        
        // File size
        description += "Size: \(ByteCountFormatter.string(fromByteCount: metadata.fileSize, countStyle: .file))"
        
        return description
    }
    
    // MARK: - Utility Methods
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(resourceValues.fileSize ?? 0)
    }
    
    func validateVideo(at url: URL) async throws -> Bool {
        let asset = AVAsset(url: url)
        
        // Check if asset is readable
        let readable = try await asset.load(.isReadable)
        guard readable else {
            throw VideoProcessorError.unreadableVideo
        }
        
        // Check duration
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        // Limit to 10 minutes for processing
        guard durationSeconds <= 600 else {
            throw VideoProcessorError.videoTooLong
        }
        
        return true
    }
    
    func getSupportedVideoFormats() -> [String] {
        return ["mp4", "mov", "avi", "m4v", "mkv"]
    }
}

// MARK: - Supporting Types

struct VideoMetadata {
    let duration: TimeInterval
    let videoTrack: VideoTrackInfo?
    let audioTrack: AudioTrackInfo?
    let fileSize: Int64
}

struct VideoTrackInfo {
    let resolution: CGSize
    let frameRate: Float
    let dataRate: Float
}

struct AudioTrackInfo {
    let dataRate: Float
}

struct FrameData {
    let time: TimeInterval
    let image: CGImage
    let size: CGSize
}

// MARK: - Error Types

enum VideoProcessorError: Error, LocalizedError {
    case invalidInputType
    case unreadableVideo
    case videoTooLong
    case frameExtractionFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidInputType:
            return "Input type is not video"
        case .unreadableVideo:
            return "Video file is not readable"
        case .videoTooLong:
            return "Video is too long (maximum 10 minutes)"
        case .frameExtractionFailed:
            return "Failed to extract video frames"
        case .unsupportedFormat:
            return "Unsupported video format"
        }
    }
}