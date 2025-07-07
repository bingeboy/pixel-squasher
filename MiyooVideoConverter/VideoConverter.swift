import Foundation
import SwiftUI

class VideoConverter: ObservableObject {
    @Published var isConverting = false
    @Published var progress: Double = 0.0
    @Published var currentFile = ""
    @Published var currentFileIndex = 0
    @Published var statusMessage = ""
    @Published var convertedFiles: [URL] = []
    
    private var currentTask: Process?
    private var totalFiles = 0
    
    func convertVideos(_ files: [URL], destinationFolder: URL? = nil) {
        guard !files.isEmpty else { return }
        
        isConverting = true
        progress = 0.0
        currentFileIndex = 0
        totalFiles = files.count
        convertedFiles.removeAll()
        statusMessage = "Checking FFmpeg installation..."
        
        // Check FFmpeg availability first
        let ffmpegPath = findFFmpegPath()
        if ffmpegPath.isEmpty {
            DispatchQueue.main.async {
                self.statusMessage = "ERROR: FFmpeg not found. Please install FFmpeg using 'brew install ffmpeg'"
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    self.isConverting = false
                    self.statusMessage = ""
                }
            }
            return
        }
        
        statusMessage = "FFmpeg found at: \(ffmpegPath)"
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds to show FFmpeg path
            DispatchQueue.main.async {
                self.statusMessage = "Starting conversion..."
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 more second
            for (index, file) in files.enumerated() {
                DispatchQueue.main.async {
                    self.currentFileIndex = index
                    self.statusMessage = "Converting file \(index + 1) of \(self.totalFiles)..."
                }
                
                DispatchQueue.main.async {
                    self.statusMessage = "Starting conversion of \(file.lastPathComponent)..."
                }
                
                await convertVideo(file, destinationFolder: destinationFolder)
                
                DispatchQueue.main.async {
                    self.progress = Double(index + 1) / Double(files.count)
                    if index + 1 < files.count {
                        self.statusMessage = "Completed \(index + 1) of \(self.totalFiles) files. Moving to next..."
                    }
                    print("DEBUG: Completed file \(index + 1) of \(files.count). Progress: \(self.progress)")
                }
            }
            
            DispatchQueue.main.async {
                self.currentFile = ""
                if self.convertedFiles.count == files.count {
                    self.statusMessage = "All files converted successfully!"
                } else {
                    self.statusMessage = "Conversion completed with \(self.convertedFiles.count) of \(files.count) files successful"
                }
                
                // Keep progress visible for 15 seconds after completion so we can see what happened
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    self.isConverting = false
                    self.statusMessage = ""
                }
            }
        }
    }
    
    private func convertVideo(_ inputFile: URL, destinationFolder: URL? = nil) async {
        let outputFileName = "converted_\(inputFile.deletingPathExtension().lastPathComponent).mp4"
        
        // Use custom destination folder if provided, otherwise use source file's folder
        let outputFolder = destinationFolder ?? inputFile.deletingLastPathComponent()
        let outputURL = outputFolder.appendingPathComponent(outputFileName)
        
        DispatchQueue.main.async {
            self.currentFile = inputFile.lastPathComponent
        }
        
        print("DEBUG: Converting \(inputFile.lastPathComponent)")
        print("DEBUG: Output will be saved to: \(outputURL.path)")
        
        let ffmpegPath = findFFmpegPath()
        guard !ffmpegPath.isEmpty else {
            DispatchQueue.main.async {
                self.statusMessage = "ERROR: FFmpeg not found. Please install FFmpeg first."
            }
            print("ERROR: FFmpeg not found in PATH")
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds so user can see error
            return
        }
        
        print("DEBUG: Using FFmpeg at: \(ffmpegPath)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        
        let arguments = [
            "-i", inputFile.path,
            "-vf", "scale=480:320:force_original_aspect_ratio=decrease,pad=480:320:(ow-iw)/2:(oh-ih)/2:black",
            "-c:v", "libx264",
            "-profile:v", "baseline",
            "-level", "3.0",
            "-b:v", "800k",
            "-maxrate", "1000k",
            "-bufsize", "1000k",
            "-c:a", "aac",
            "-b:a", "64k",
            "-ar", "22050",
            "-ac", "2",
            "-f", "mp4",
            "-movflags", "+faststart",
            "-y",
            outputURL.path
        ]
        
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        currentTask = process
        
        print("DEBUG: Starting FFmpeg process...")
        print("DEBUG: FFmpeg command: \(ffmpegPath) \(arguments.joined(separator: " "))")
        DispatchQueue.main.async {
            self.statusMessage = "Running FFmpeg conversion..."
        }
        
        do {
            try process.run()
            print("DEBUG: FFmpeg process started, waiting for completion...")
            process.waitUntilExit()
            
            // Capture the output/error from FFmpeg
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "No output"
            
            print("DEBUG: FFmpeg process completed with status: \(process.terminationStatus)")
            print("DEBUG: FFmpeg output: \(output)")
            
            if process.terminationStatus == 0 {
                // Check if the output file actually exists
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    DispatchQueue.main.async {
                        self.convertedFiles.append(outputURL)
                        self.statusMessage = "Successfully converted \(inputFile.lastPathComponent)"
                    }
                    print("DEBUG: Successfully converted \(inputFile.lastPathComponent)")
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Conversion completed but output file not found: \(outputURL.path)"
                    }
                    print("ERROR: Output file not found: \(outputURL.path)")
                }
            } else {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to convert \(inputFile.lastPathComponent) (exit code: \(process.terminationStatus))"
                }
                print("ERROR: Conversion failed for \(inputFile.lastPathComponent) with exit code: \(process.terminationStatus)")
                print("ERROR: FFmpeg error output: \(output)")
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "ERROR: Failed to run FFmpeg - \(error.localizedDescription)"
            }
            print("ERROR: Failed to run FFmpeg: \(error)")
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds so user can see error
        }
        
        currentTask = nil
    }
    
    private func findFFmpegPath() -> String {
        let possiblePaths = [
            "/usr/local/bin/ffmpeg",
            "/opt/homebrew/bin/ffmpeg",
            "/usr/bin/ffmpeg",
            "/bin/ffmpeg"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    return output.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } catch {
            print("Error finding FFmpeg: \(error)")
        }
        
        return ""
    }
    
    func cancelConversion() {
        currentTask?.terminate()
        currentTask = nil
        
        DispatchQueue.main.async {
            self.isConverting = false
            self.currentFile = ""
            self.currentFileIndex = 0
            self.progress = 0.0
            self.statusMessage = "Conversion cancelled"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.statusMessage = ""
            }
        }
    }
}