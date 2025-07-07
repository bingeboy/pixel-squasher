import SwiftUI

struct TestView: View {
    var body: some View {
        VStack {
            Text("Test App")
                .font(.title)
            
            HStack {
                Button("Button 1") {
                    print("Button 1 pressed")
                }
                .buttonStyle(.borderedProminent)
                
                Button("📁 Choose Folder") {
                    print("Choose Folder pressed")
                }
                .buttonStyle(.borderedProminent)
                .background(Color.orange)
                
                Button("Button 3") {
                    print("Button 3 pressed")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 400, height: 200)
    }
}

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            TestView()
        }
    }
}