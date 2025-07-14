import SwiftUI
import AVFoundation
import AVKit

struct ContentView: View {
    @StateObject private var converter = VideoConverter()
    @State private var selectedFiles: [URL] = []
    @State private var isDragging = false
    @State private var destinationFolder: URL?
    @State private var showLogTray = false
    @State private var showSettings = false
    @State private var selectedTab = 0
    @State private var youtubeURL = ""
    @State private var showYouTubeInput = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("PixelSquasher")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Main toolbar buttons
                HStack(spacing: 8) {
                    Button(action: { selectFiles() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add Files")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showYouTubeInput.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                            Text("YouTube")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { selectDestination() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text("Output")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { convertVideos() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                            Text("Convert")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(converter.isConverting || selectedFiles.isEmpty)
                    
                    Divider()
                        .frame(height: 20)
                    
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showLogTray.toggle() }) {
                        Image(systemName: "list.bullet.rectangle")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Main content area
            HSplitView {
                // Left panel - File management
                VStack(spacing: 0) {
                    // Tab bar
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = 0 }) {
                            Text("Input Files")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderless)
                        .background(selectedTab == 0 ? Color.accentColor.opacity(0.2) : Color.clear)
                        
                        Button(action: { selectedTab = 1 }) {
                            Text("Output Files")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderless)
                        .background(selectedTab == 1 ? Color.accentColor.opacity(0.2) : Color.clear)
                        
                        Spacer()
                        
                        if selectedTab == 0 {
                            Text("\(selectedFiles.count) files")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(converter.convertedFiles.count) files")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        FileListView(files: $selectedFiles, 
                                   converter: converter, 
                                   isDragging: $isDragging)
                    } else {
                        OutputListView(files: converter.convertedFiles)
                    }
                }
                .frame(minWidth: 300)
                
                // Right panel - Status and controls
                VStack(spacing: 0) {
                    // Status area
                    StatusView(converter: converter, 
                             selectedFiles: selectedFiles,
                             destinationFolder: destinationFolder)
                    
                    if showSettings {
                        Divider()
                        SettingsPanel()
                            .frame(maxHeight: 200)
                    }
                }
                .frame(minWidth: 250)
            }
        }
        .frame(minWidth: 800, maxWidth: showLogTray ? 1200 : 1000, 
               minHeight: 500, maxHeight: 800)
        .overlay(
            // Log Tray
            HStack {
                Spacer()
                if showLogTray {
                    LogTrayView(showLogTray: $showLogTray)
                        .frame(width: 300)
                        .transition(.move(edge: .trailing))
                }
            },
            alignment: .trailing
        )
        .overlay(
            // YouTube URL Input Modal
            Group {
                if showYouTubeInput {
                    YouTubeInputView(
                        showYouTubeInput: $showYouTubeInput,
                        youtubeURL: $youtubeURL,
                        onDownload: { url in
                            downloadYouTubeVideo(url)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .onAppear {
            print("DEBUG: ContentView appeared")
            let debugMsg = "DEBUG: ContentView appeared at \(Date())\n"
            try? debugMsg.write(to: URL(fileURLWithPath: "/tmp/pixelsquasher_ui_debug.log"), atomically: false, encoding: .utf8)
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
            let url = URL(fileURLWithPath: "/tmp/pixelsquasher_ui_debug.log")
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
    
    private func downloadYouTubeVideo(_ url: String) {
        converter.downloadAndConvertYouTubeVideo(url, destinationFolder: destinationFolder)
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

// MARK: - Functional UI Components

struct FileListView: View {
    @Binding var files: [URL]
    let converter: VideoConverter
    @Binding var isDragging: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if files.isEmpty {
                DropZoneCompact(selectedFiles: $files, isDragging: $isDragging)
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(files.enumerated()), id: \.offset) { index, file in
                        FileRowView(file: file, 
                                  index: index, 
                                  converter: converter,
                                  onRemove: {
                                      files.remove(at: index)
                                  })
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct FileRowView: View {
    let file: URL
    let index: Int
    let converter: VideoConverter
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            VideoThumbnailView(url: file)
                .frame(width: 32, height: 20)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.lastPathComponent)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(formatFileSize(file))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            Group {
                if converter.isConverting && index < converter.currentFileIndex {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else if converter.isConverting && index == converter.currentFileIndex {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 2)
        .background(index == converter.currentFileIndex && converter.isConverting ? 
                   Color.accentColor.opacity(0.1) : Color.clear)
    }
    
    private func formatFileSize(_ fileURL: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return "Unknown"
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

struct OutputListView: View {
    let files: [URL]
    
    var body: some View {
        if files.isEmpty {
            VStack {
                Image(systemName: "tray")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No converted files yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(files, id: \.self) { file in
                HStack {
                    Image(systemName: "doc.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.lastPathComponent)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Text(file.path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
                    }) {
                        Image(systemName: "folder")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 2)
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct StatusView: View {
    let converter: VideoConverter
    let selectedFiles: [URL]
    let destinationFolder: URL?
    
    var body: some View {
        VStack(spacing: 8) {
            // Destination info
            if let destination = destinationFolder {
                HStack {
                    Text("Output:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(destination.lastPathComponent)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
            }
            
            // Progress section
            if converter.isConverting {
                VStack(spacing: 6) {
                    HStack {
                        Text("Converting")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(converter.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    ProgressView(value: converter.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    if !converter.currentFile.isEmpty {
                        HStack {
                            Text("File:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(converter.currentFile)
                                .font(.caption2)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Text("\(converter.currentFileIndex + 1) of \(selectedFiles.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        if !converter.conversionSpeed.isEmpty {
                            Text(converter.conversionSpeed)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if converter.currentFileIndex > 0 || !converter.convertedFiles.isEmpty {
                        Button("Cancel") {
                            converter.cancelConversion()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            } else {
                VStack(spacing: 4) {
                    Text("Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: 0.0)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            
            // Status message
            if !converter.statusMessage.isEmpty {
                Text(converter.statusMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
            
            Spacer()
        }
        .padding(8)
    }
}

struct SettingsPanel: View {
    @State private var videoQuality = "800k"
    @State private var audioQuality = "64k"
    @State private var outputFormat = "mp4"
    @State private var customWidth = "480"
    @State private var customHeight = "320"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Conversion Settings")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    SettingRow(title: "Video Quality", 
                             value: $videoQuality,
                             options: ["400k", "800k", "1200k", "1600k"])
                    
                    SettingRow(title: "Audio Quality", 
                             value: $audioQuality,
                             options: ["32k", "64k", "128k", "192k"])
                    
                    SettingRow(title: "Format", 
                             value: $outputFormat,
                             options: ["mp4", "mkv", "avi"])
                    
                    HStack {
                        Text("Resolution:")
                            .font(.caption2)
                            .frame(width: 70, alignment: .leading)
                        
                        TextField("", text: $customWidth)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                        
                        Text("×")
                            .font(.caption2)
                        
                        TextField("", text: $customHeight)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                        
                        Spacer()
                    }
                }
                .padding(8)
            }
        }
    }
}

struct SettingRow: View {
    let title: String
    @Binding var value: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text("\(title):")
                .font(.caption2)
                .frame(width: 70, alignment: .leading)
            
            Picker("", selection: $value) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)
            
            Spacer()
        }
    }
}

struct DropZoneCompact: View {
    @Binding var selectedFiles: [URL]
    @Binding var isDragging: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.rectangle.on.folder")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("Drop files here or use Add Files button")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDragging ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDragging ? Color.accentColor : Color.gray.opacity(0.3), 
                       style: StrokeStyle(lineWidth: 2, dash: [8]))
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
            selectedFiles.append(contentsOf: urls)
        }
        
        return true
    }
}

struct YouTubeInputView: View {
    @Binding var showYouTubeInput: Bool
    @Binding var youtubeURL: String
    let onDownload: (String) -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showYouTubeInput = false
                }
            
            // Modal content
            VStack(spacing: 16) {
                Text("Download from YouTube")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Enter a YouTube URL to download and convert")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("https://youtube.com/watch?v=...", text: $youtubeURL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 400)
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        showYouTubeInput = false
                        youtubeURL = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Download & Convert") {
                        if !youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onDownload(youtubeURL)
                            showYouTubeInput = false
                            youtubeURL = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
}

struct LogTrayView: View {
    @Binding var showLogTray: Bool
    @State private var logContent = ""
    @State private var timer: Timer?
    @State private var isAtBottom = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Conversion Log")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(logContent, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .help("Copy log to clipboard")
                
                Button(action: {
                    logContent = ""
                }) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .help("Clear log")
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLogTray.toggle()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.bordered)
                .help("Close log")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Log content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if logContent.isEmpty {
                            Text("No log data yet...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(logContent.components(separatedBy: "\n").indices, id: \.self) { index in
                                let line = logContent.components(separatedBy: "\n")[index]
                                if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(line)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(colorForLogLine(line))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 8)
                                        .id(index)
                                }
                            }
                        }
                    }
                }
                .onChange(of: logContent) { _ in
                    if isAtBottom {
                        withAnimation(.easeOut(duration: 0.3)) {
                            let lines = logContent.components(separatedBy: "\n")
                            if !lines.isEmpty {
                                proxy.scrollTo(lines.count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .background(Color.black.opacity(0.05))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 5, x: -2, y: 0)
        .onAppear {
            startLogMonitoring()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func colorForLogLine(_ line: String) -> Color {
        if line.contains("ERROR") || line.contains("Failed") {
            return .red
        } else if line.contains("Progress:") || line.contains("Duration parsed:") {
            return .blue
        } else if line.contains("UI Events") || line.contains("Conversion Log") {
            return .primary
        } else if line.contains("FFmpeg:") {
            return .secondary
        } else {
            return .primary
        }
    }
    
    private func startLogMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            var combinedLog = ""
            
            // Read UI debug log
            if let uiLog = try? String(contentsOfFile: "/tmp/pixelsquasher_ui_debug.log") {
                combinedLog += "=== UI Events ===\n" + uiLog + "\n"
            }
            
            // Read conversion debug log
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let debugLogPath = documentsPath.appendingPathComponent("pixelsquasher_debug.log").path
            if let conversionLog = try? String(contentsOfFile: debugLogPath) {
                combinedLog += "=== Conversion Log ===\n" + conversionLog
            }
            
            if !combinedLog.isEmpty {
                // Keep only the last 100 lines to prevent the log from getting too large
                let lines = combinedLog.components(separatedBy: "\n")
                let recentLines = Array(lines.suffix(100))
                let newContent = recentLines.joined(separator: "\n")
                
                if newContent != logContent {
                    logContent = newContent
                }
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