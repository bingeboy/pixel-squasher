import Foundation
import SwiftUI

extension String {
    func appendToFile(atPath path: String) throws {
        let data = self.data(using: .utf8)!
        if FileManager.default.fileExists(atPath: path) {
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try data.write(to: URL(fileURLWithPath: path))
        }
    }
}

class VideoConverter: ObservableObject {
    @Published var isConverting = false
    @Published var progress: Double = 0.0
    @Published var currentFile = ""
    @Published var currentFileIndex = 0
    @Published var statusMessage = ""
    @Published var convertedFiles: [URL] = []
    @Published var currentProcessingTime = ""
    @Published var totalVideoDuration = ""
    @Published var conversionSpeed = ""
    
    private var currentTask: Process?
    private var totalFiles = 0
    
    func convertVideos(_ files: [URL], destinationFolder: URL? = nil) {
        guard !files.isEmpty else { return }
        
        print("DEBUG: convertVideos called with \(files.count) files")
        
        isConverting = true
        progress = 0.0
        currentFileIndex = 0
        totalFiles = files.count
        convertedFiles.removeAll()
        currentProcessingTime = ""
        totalVideoDuration = ""
        conversionSpeed = ""
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
        print("DEBUG: convertVideo called with file: \(inputFile.path)")
        
        let outputFileName = "converted_\(inputFile.deletingPathExtension().lastPathComponent).mp4"
        
        // Use custom destination folder if provided, otherwise use source file's folder
        let outputFolder = destinationFolder ?? inputFile.deletingLastPathComponent()
        let outputURL = outputFolder.appendingPathComponent(outputFileName)
        
        print("DEBUG: Output URL calculated as: \(outputURL.path)")
        
        DispatchQueue.main.async {
            self.currentFile = inputFile.lastPathComponent
        }
        
        print("DEBUG: Converting \(inputFile.lastPathComponent)")
        print("DEBUG: Output will be saved to: \(outputURL.path)")
        
        // Write debug info to a file we can check
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let debugLogPath = documentsPath.appendingPathComponent("miyoo_debug.log").path
        let debugInfo = "=== CONVERSION START ===\nInput: \(inputFile.path)\nOutput: \(outputURL.path)\nTime: \(Date())\n"
        do {
            try debugInfo.write(toFile: debugLogPath, atomically: true, encoding: .utf8)
            print("DEBUG: Log written to \(debugLogPath)")
        } catch {
            print("DEBUG: Failed to write log: \(error)")
        }
        
        // Check if input file is readable
        print("DEBUG: Checking if input file is readable: \(inputFile.path)")
        guard FileManager.default.isReadableFile(atPath: inputFile.path) else {
            let errorMsg = "ERROR: Cannot read input file: \(inputFile.path)"
            print(errorMsg)
            DispatchQueue.main.async {
                self.statusMessage = errorMsg
            }
            // Log the error
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let debugLogPath = documentsPath.appendingPathComponent("miyoo_debug.log").path
            try? "\(errorMsg)\n".appendToFile(atPath: debugLogPath)
            return
        }
        print("DEBUG: Input file is readable")
        
        // Check if output directory is writable
        let outputDir = outputURL.deletingLastPathComponent()
        print("DEBUG: Checking if output directory is writable: \(outputDir.path)")
        guard FileManager.default.isWritableFile(atPath: outputDir.path) else {
            let errorMsg = "ERROR: Cannot write to output directory: \(outputDir.path)"
            print(errorMsg)
            DispatchQueue.main.async {
                self.statusMessage = errorMsg
            }
            // Log the error
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let debugLogPath = documentsPath.appendingPathComponent("miyoo_debug.log").path
            try? "\(errorMsg)\n".appendToFile(atPath: debugLogPath)
            return
        }
        print("DEBUG: Output directory is writable")
        
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
        print("DEBUG: Input file size: \((try? FileManager.default.attributesOfItem(atPath: inputFile.path)[.size] as? Int64) ?? 0) bytes")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        
        // Use shell to properly handle file paths with spaces
        let escapedInputPath = inputFile.path.replacingOccurrences(of: "'", with: "'\"'\"'")
        let escapedOutputPath = outputURL.path.replacingOccurrences(of: "'", with: "'\"'\"'")
        
        let shellCommand = """
        '\(ffmpegPath)' -i '\(escapedInputPath)' \
        -vf 'scale=480:320:force_original_aspect_ratio=decrease,pad=480:320:(ow-iw)/2:(oh-ih)/2:black' \
        -c:v libx264 \
        -profile:v baseline \
        -level 3.0 \
        -b:v 800k \
        -maxrate 1000k \
        -bufsize 1000k \
        -c:a aac \
        -b:a 64k \
        -ar 22050 \
        -ac 2 \
        -f mp4 \
        -movflags +faststart \
        -progress pipe:1 \
        -y '\(escapedOutputPath)'
        """
        
        process.arguments = ["-c", shellCommand]
        
        print("DEBUG: Shell command: \(shellCommand)")
        
        // Also write the shell command to the debug log
        do {
            let commandInfo = "Shell command: \(shellCommand)\n"
            try commandInfo.appendToFile(atPath: debugLogPath)
        } catch {
            print("DEBUG: Failed to append command to log: \(error)")
        }
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        currentTask = process
        
        print("DEBUG: Starting FFmpeg process...")
        print("DEBUG: Shell command: \(shellCommand)")
        DispatchQueue.main.async {
            self.statusMessage = "Running FFmpeg conversion..."
        }
        
        do {
            try process.run()
            print("DEBUG: FFmpeg process started, waiting for completion...")
            
            // Log that process started
            do {
                let startInfo = "Process started at: \(Date())\n"
                try startInfo.appendToFile(atPath: debugLogPath)
            } catch {
                print("DEBUG: Failed to log process start: \(error)")
            }
            
            // Parse FFmpeg progress in real-time
            let progressQueue = DispatchQueue(label: "ffmpeg-progress")
            var videoDuration: Double = 0
            var currentTime: Double = 0
            let conversionStartTime = Date()
            
            // Write initial log entry
            let logEntry = "[\(Date())] Starting conversion of \(inputFile.lastPathComponent)\n"
            try? logEntry.appendToFile(atPath: debugLogPath)
            
            progressQueue.async {
                let outputHandle = outputPipe.fileHandleForReading
                let errorHandle = errorPipe.fileHandleForReading
                
                while process.isRunning {
                    // Check both stdout and stderr for progress
                    let outputData = outputHandle.availableData
                    let errorData = errorHandle.availableData
                    
                    for data in [outputData, errorData] {
                        if data.count > 0 {
                            if let output = String(data: data, encoding: .utf8) {
                                // Log all FFmpeg output for debugging
                                let logEntry = "[\(Date())] FFmpeg: \(output)\n"
                                try? logEntry.appendToFile(atPath: debugLogPath)
                                
                                let lines = output.components(separatedBy: .newlines)
                                for line in lines {
                                    let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    // Parse duration from stderr (most common format)
                                    if cleanLine.contains("Duration:") {
                                        // Look for pattern like "Duration: 01:23:45.67"
                                        if let range = cleanLine.range(of: "Duration: ") {
                                            let afterDuration = String(cleanLine[range.upperBound...])
                                            let components = afterDuration.components(separatedBy: ",")
                                            if let timeStr = components.first {
                                                let timeOnly = timeStr.trimmingCharacters(in: .whitespacesAndNewlines)
                                                if let duration = self.parseTimeString(timeOnly) {
                                                    videoDuration = duration
                                                    let logEntry = "[\(Date())] Duration parsed: \(duration) seconds\n"
                                                    try? logEntry.appendToFile(atPath: debugLogPath)
                                                    DispatchQueue.main.async {
                                                        self.totalVideoDuration = self.formatTime(seconds: videoDuration)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Parse progress from -progress pipe:1 output
                                    if cleanLine.hasPrefix("out_time_us=") {
                                        let timeString = String(cleanLine.dropFirst(12))
                                        if let timeMicroseconds = Double(timeString) {
                                            currentTime = timeMicroseconds / 1_000_000
                                            let logEntry = "[\(Date())] Progress: \(currentTime) / \(videoDuration) seconds\n"
                                            try? logEntry.appendToFile(atPath: debugLogPath)
                                            self.updateProgress(currentTime: currentTime, videoDuration: videoDuration, startTime: conversionStartTime)
                                        }
                                    }
                                    
                                    // Also parse time= from stderr as fallback
                                    if cleanLine.contains("time=") && !cleanLine.contains("Duration:") {
                                        let components = cleanLine.components(separatedBy: " ")
                                        for component in components {
                                            if component.hasPrefix("time=") {
                                                let timeString = String(component.dropFirst(5))
                                                if let time = self.parseTimeString(timeString) {
                                                    currentTime = time
                                                    let logEntry = "[\(Date())] Time progress: \(time) seconds\n"
                                                    try? logEntry.appendToFile(atPath: debugLogPath)
                                                    self.updateProgress(currentTime: currentTime, videoDuration: videoDuration, startTime: conversionStartTime)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            
            // Add timeout mechanism
            let timeout: TimeInterval = 300 // 5 minutes timeout
            let startTime = Date()
            
            DispatchQueue.global(qos: .background).async {
                while process.isRunning && Date().timeIntervalSince(startTime) < timeout {
                    Thread.sleep(forTimeInterval: 1.0)
                }
                
                if Date().timeIntervalSince(startTime) >= timeout && process.isRunning {
                    DispatchQueue.main.async {
                        self.statusMessage = "Conversion timed out after 5 minutes, terminating..."
                    }
                    process.terminate()
                }
            }
            
            process.waitUntilExit()
            print("DEBUG: Process completed after \(Date().timeIntervalSince(startTime)) seconds")
            
            // Capture the output and error from FFmpeg separately
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let outputText = String(data: outputData, encoding: .utf8) ?? "No output"
            let errorText = String(data: errorData, encoding: .utf8) ?? "No error output"
            
            print("DEBUG: FFmpeg process completed with status: \(process.terminationStatus)")
            print("DEBUG: FFmpeg stdout: \(outputText)")
            print("DEBUG: FFmpeg stderr: \(errorText)")
            
            // Check if the output file actually exists first
            let fileExists = FileManager.default.fileExists(atPath: outputURL.path)
            let fileSize = fileExists ? (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0 : 0
            
            print("DEBUG: Output file exists: \(fileExists), Size: \(fileSize) bytes")
            
            // Write debug result to file
            let debugResult = """
            === CONVERSION RESULT ===
            Exit code: \(process.terminationStatus)
            File exists: \(fileExists)
            File size: \(fileSize) bytes
            FFmpeg stdout: \(outputText)
            FFmpeg stderr: \(errorText)
            Time: \(Date())
            
            """
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let debugLogPath = documentsPath.appendingPathComponent("miyoo_debug.log").path
            try? debugResult.appendToFile(atPath: debugLogPath)
            
            if process.terminationStatus == 0 {
                if fileExists && fileSize > 0 {
                    DispatchQueue.main.async {
                        self.convertedFiles.append(outputURL)
                        self.statusMessage = "Successfully converted \(inputFile.lastPathComponent) (\(fileSize) bytes)"
                    }
                    print("DEBUG: Successfully converted \(inputFile.lastPathComponent)")
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Conversion completed but output file not found or empty: \(outputURL.path)"
                    }
                    print("ERROR: Output file not found or empty: \(outputURL.path)")
                }
            } else {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to convert \(inputFile.lastPathComponent) (exit code: \(process.terminationStatus))"
                }
                print("ERROR: Conversion failed for \(inputFile.lastPathComponent) with exit code: \(process.terminationStatus)")
                print("ERROR: FFmpeg error output: \(errorText)")
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
            self.currentProcessingTime = ""
            self.totalVideoDuration = ""
            self.conversionSpeed = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.statusMessage = ""
            }
        }
    }
    
    private func updateProgress(currentTime: Double, videoDuration: Double, startTime: Date) {
        let currentTimeFormatted = formatTime(seconds: currentTime)
        let totalTimeFormatted = formatTime(seconds: videoDuration)
        
        if videoDuration > 0 {
            let progressPercent = min(currentTime / videoDuration, 1.0)
            let elapsedTime = Date().timeIntervalSince(startTime)
            let speed = elapsedTime > 0 ? currentTime / elapsedTime : 0.0
            
            DispatchQueue.main.async {
                // Calculate overall progress across all files
                let fileProgress = Double(self.currentFileIndex) / Double(self.totalFiles)
                let currentFileProgress = progressPercent / Double(self.totalFiles)
                self.progress = fileProgress + currentFileProgress
                
                self.statusMessage = "Converting \(self.currentFile) - \(Int(progressPercent * 100))%"
                self.currentProcessingTime = currentTimeFormatted
                self.totalVideoDuration = totalTimeFormatted
                self.conversionSpeed = String(format: "%.1fx", speed)
                
                // Log progress update
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let debugLogPath = documentsPath.appendingPathComponent("miyoo_debug.log").path
                let logEntry = "[\(Date())] UI Progress: \(Int(self.progress * 100))% overall, \(Int(progressPercent * 100))% current file\n"
                try? logEntry.appendToFile(atPath: debugLogPath)
            }
        } else {
            DispatchQueue.main.async {
                self.currentProcessingTime = currentTimeFormatted
                self.statusMessage = "Converting \(self.currentFile) - Processing..."
            }
        }
    }
    
    private func formatTime(seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private func parseTimeString(_ timeString: String) -> Double? {
        // Parse time format like "00:01:23.45" or "01:23.45"
        let components = timeString.components(separatedBy: ":")
        var totalSeconds: Double = 0
        
        if components.count == 3 {
            // Format: HH:MM:SS.ss
            if let hours = Double(components[0]),
               let minutes = Double(components[1]),
               let seconds = Double(components[2]) {
                totalSeconds = hours * 3600 + minutes * 60 + seconds
            }
        } else if components.count == 2 {
            // Format: MM:SS.ss
            if let minutes = Double(components[0]),
               let seconds = Double(components[1]) {
                totalSeconds = minutes * 60 + seconds
            }
        } else if components.count == 1 {
            // Format: SS.ss
            if let seconds = Double(components[0]) {
                totalSeconds = seconds
            }
        }
        
        return totalSeconds > 0 ? totalSeconds : nil
    }
}