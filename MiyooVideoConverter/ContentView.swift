import SwiftUI
import AVFoundation
import AVKit

struct ContentView: View {
    @StateObject private var converter = VideoConverter()
    @State private var selectedFiles: [URL] = []
    @State private var isDragging = false
    @State private var destinationFolder: URL?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Miyoo Mini Plus Video Converter")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Convert videos for optimal playback on Miyoo Mini Plus")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                
                DropZone(
                    selectedFiles: $selectedFiles,
                    isDragging: $isDragging
                )
                .frame(height: 150)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Files (\(selectedFiles.count)):")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            if selectedFiles.isEmpty {
                                Text("No files selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, file in
                                    HStack(spacing: 12) {
                                        // Video thumbnail
                                        VideoThumbnailView(url: file)
                                            .frame(width: 60, height: 40)
                                            .cornerRadius(6)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(file.lastPathComponent)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                            
                                            Text(formatFileSize(file))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if converter.isConverting && index < converter.currentFileIndex {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title2)
                                        } else if converter.isConverting && index == converter.currentFileIndex {
                                            VStack(spacing: 4) {
                                                ProgressView()
                                                    .scaleEffect(0.7)
                                                Text("Converting...")
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(index == converter.currentFileIndex && converter.isConverting ? 
                                                  Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(index == converter.currentFileIndex && converter.isConverting ? 
                                                           Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                                                    .scaleEffect(index == converter.currentFileIndex && converter.isConverting ? 1.05 : 1.0)
                                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), 
                                                              value: converter.isConverting && index == converter.currentFileIndex)
                                            )
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                }
                
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button("Select Files") {
                            selectFiles()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Clear") {
                            selectedFiles.removeAll()
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedFiles.isEmpty || converter.isConverting)
                        
                        Spacer()
                        
                        Button("Convert All") {
                            convertVideos()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(converter.isConverting || selectedFiles.isEmpty)
                    }
                    
                    HStack(spacing: 12) {
                        Button("📁 Choose Folder") {
                            selectDestination()
                        }
                        .buttonStyle(.bordered)
                        
                        if destinationFolder != nil {
                            Button("Reset Destination") {
                                destinationFolder = nil
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            if let destination = destinationFolder {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Output Destination:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("📁 \(destination.lastPathComponent)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
            
            VStack(spacing: 16) {
                if converter.isConverting {
                    HStack {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Converting Video")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        Text("\(Int(converter.progress * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: converter.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(1.0, anchor: .center)
                    
                    // Current file info with enhanced styling
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current File:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(converter.currentFile.isEmpty ? "Preparing..." : converter.currentFile)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Progress:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(converter.currentFileIndex + 1) of \(selectedFiles.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        // Processing animation
                        HStack {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(converter.isConverting ? 1.0 : 0.5)
                                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: converter.isConverting)
                            }
                            Text("Processing...")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    
                    // Timing information
                    if !converter.currentProcessingTime.isEmpty || !converter.totalVideoDuration.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time Progress:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(converter.currentProcessingTime) / \(converter.totalVideoDuration)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            if !converter.conversionSpeed.isEmpty {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Speed:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(converter.conversionSpeed)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    
                    if converter.currentFileIndex > 0 || !converter.convertedFiles.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Status:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(converter.statusMessage)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            Button("Cancel") {
                                converter.cancelConversion()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Ready to convert")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        ProgressView(value: 0.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                    }
                    .padding()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            HStack(spacing: 20) {
                // Left side - Converted Files
                VStack(alignment: .leading, spacing: 10) {
                    Text("Converted Files (\(converter.convertedFiles.count)):")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            if converter.convertedFiles.isEmpty {
                                Text("No files converted yet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(converter.convertedFiles, id: \.self) { file in
                                    HStack {
                                        Text(file.lastPathComponent)
                                            .font(.caption)
                                        Spacer()
                                        Button("Show in Finder") {
                                            NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
                
                // Right side - Log Window
                VStack(alignment: .leading, spacing: 10) {
                    Text("Conversion Log:")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            LogView()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .padding(8)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 900, maxWidth: 1200, minHeight: 700, maxHeight: 1000)
        .onAppear {
            print("DEBUG: ContentView appeared")
            let debugMsg = "DEBUG: ContentView appeared at \(Date())\n"
            try? debugMsg.write(to: URL(fileURLWithPath: "/tmp/miyoo_ui_debug.log"), atomically: false, encoding: .utf8)
        }
    }
    
    private func selectFiles() {
        print("DEBUG: selectFiles called")
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.movie, .video]
        
        if panel.runModal() == .OK {
            selectedFiles = panel.urls
            print("DEBUG: Selected \(selectedFiles.count) files: \(selectedFiles.map { $0.lastPathComponent })")
        }
    }
    
    private func selectDestination() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Destination Folder"
        
        if panel.runModal() == .OK {
            destinationFolder = panel.url
        }
    }
    
    private func convertVideos() {
        print("DEBUG: UI convertVideos button clicked with \(selectedFiles.count) files")
        let debugMsg = "DEBUG: UI convertVideos button clicked with \(selectedFiles.count) files at \(Date())\n"
        if let data = debugMsg.data(using: .utf8) {
            let url = URL(fileURLWithPath: "/tmp/miyoo_ui_debug.log")
            if FileManager.default.fileExists(atPath: url.path) {
                if let fileHandle = try? FileHandle(forWritingTo: url) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: url)
            }
        }
        converter.convertVideos(selectedFiles, destinationFolder: destinationFolder)
    }
    
    private func formatFileSize(_ fileURL: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return "Unknown size"
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

struct LogView: View {
    @State private var logContent = ""
    @State private var timer: Timer?
    
    var body: some View {
        Text(logContent.isEmpty ? "No log data yet..." : logContent)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                startLogMonitoring()
            }
            .onDisappear {
                timer?.invalidate()
            }
    }
    
    private func startLogMonitoring() {
        // Check both UI debug log and conversion debug log
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            var combinedLog = ""
            
            // Read UI debug log
            if let uiLog = try? String(contentsOfFile: "/tmp/miyoo_ui_debug.log") {
                combinedLog += "=== UI Events ===\\n" + uiLog + "\\n"
            }
            
            // Read conversion debug log
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let debugLogPath = documentsPath.appendingPathComponent("miyoo_debug.log").path
            if let conversionLog = try? String(contentsOfFile: debugLogPath) {
                combinedLog += "=== Conversion Log ===\\n" + conversionLog
            }
            
            if !combinedLog.isEmpty {
                // Keep only the last 50 lines to prevent the log from getting too large
                let lines = combinedLog.components(separatedBy: .newlines)
                let recentLines = Array(lines.suffix(50))
                logContent = recentLines.joined(separator: "\\n")
            }
        }
    }
}

struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "video")
                                .foregroundColor(.gray)
                                .font(.caption)
                            if thumbnail == nil {
                                ProgressView()
                                    .scaleEffect(0.5)
                            }
                        }
                    )
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        Task {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 120, height: 80)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                
                await MainActor.run {
                    self.thumbnail = nsImage
                }
            } catch {
                print("Failed to generate thumbnail: \(error)")
            }
        }
    }
}

struct DropZone: View {
    @Binding var selectedFiles: [URL]
    @Binding var isDragging: Bool
    
    var body: some View {
        Rectangle()
            .fill(isDragging ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .overlay(
                VStack {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text(selectedFiles.isEmpty ? "Drop video files here or click 'Select Files'" : "\(selectedFiles.count) file(s) selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDragging ? Color.blue : Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers: providers)
            }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url, url.hasDirectoryPath == false {
                        let pathExtension = url.pathExtension.lowercased()
                        if ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm"].contains(pathExtension) {
                            urls.append(url)
                        }
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            selectedFiles = urls
        }
        
        return true
    }
}

#Preview {
    ContentView()
}