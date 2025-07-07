import SwiftUI

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
                
                if !selectedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Files (\(selectedFiles.count)):")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, file in
                                    HStack {
                                        Image(systemName: "video")
                                            .foregroundColor(.blue)
                                        Text(file.lastPathComponent)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                        if converter.isConverting && index < converter.currentFileIndex {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else if converter.isConverting && index == converter.currentFileIndex {
                                            ProgressView()
                                                .scaleEffect(0.5)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(index == converter.currentFileIndex && converter.isConverting ? 
                                                  Color.blue.opacity(0.1) : Color.clear)
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                    }
                }
                
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button("Select Files") {
                            selectFiles()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if !selectedFiles.isEmpty && !converter.isConverting {
                            Button("Clear") {
                                selectedFiles.removeAll()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        if !selectedFiles.isEmpty {
                            Button("Convert All") {
                                convertVideos()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(converter.isConverting)
                        }
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
            
            if converter.isConverting {
                VStack(spacing: 12) {
                    HStack {
                        Text("Conversion Progress")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(converter.progress * 100))%")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: converter.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
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
                            Text("Files:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(converter.currentFileIndex + 1) of \(selectedFiles.count)")
                                .font(.subheadline)
                                .fontWeight(.medium)
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
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            if !converter.convertedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Converted Files:")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
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
                    .frame(maxHeight: 100)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 600, maxWidth: 800, minHeight: 500, maxHeight: 700)
    }
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.movie, .video]
        
        if panel.runModal() == .OK {
            selectedFiles = panel.urls
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
        converter.convertVideos(selectedFiles, destinationFolder: destinationFolder)
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