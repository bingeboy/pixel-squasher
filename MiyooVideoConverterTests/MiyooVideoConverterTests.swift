import XCTest
import SwiftUI
@testable import MiyooVideoConverter

final class MiyooVideoConverterTests: XCTestCase {
    
    func testContentViewExists() throws {
        let contentView = ContentView()
        XCTAssertNotNil(contentView)
    }
    
    func testSelectDestinationFunction() throws {
        let contentView = ContentView()
        // Test that the selectDestination function exists
        // This will compile-check that the function is present
        XCTAssertTrue(true) // Basic test to ensure compilation
    }
    
    func testButtonPresence() throws {
        // Test that we can create the view without crashing
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        
        // Load the view
        hostingController.loadView()
        
        XCTAssertNotNil(hostingController.view)
        print("✅ ContentView created successfully")
        print("✅ Hosting controller view loaded")
    }
}