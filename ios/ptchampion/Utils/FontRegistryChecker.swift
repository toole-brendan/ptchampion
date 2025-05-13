import UIKit
import SwiftUI

/// Debug utility to check if fonts are properly registered
struct FontRegistryChecker {
    static func checkFonts() {
        #if DEBUG
        // Only run this check in debug mode
        let fontsToCheck = [
            // Existing fonts
            "Montserrat-Regular",
            "Montserrat-Bold",
            "Montserrat-SemiBold",
            "RobotoMono-Medium",
            
            // New Futura PT fonts
            "FuturaPT-Book",
            "FuturaPT-Medium",
            "FuturaPT-Demi", 
            "FuturaPT-Bold"
        ]
        
        print("🔤 Checking font registration...")
        
        var allRegistered = true
        for fontName in fontsToCheck {
            if let _ = UIFont(name: fontName, size: 16) {
                print("✅ \"\(fontName)\" is registered")
            } else {
                print("❌ \"\(fontName)\" NOT FOUND")
                allRegistered = false
            }
        }
        
        if !allRegistered {
            print("⚠️ Some fonts are not registered properly.")
            print("- Check that fonts are in Resources/Fonts folder")
            print("- Check Info.plist has <key>UIAppFonts</key> with all font filenames")
            print("- Try cleaning the build folder and rebuild")
        }
        
        // Print all available fonts for debugging
        print("\n📋 All available fonts in the app:")
        for family in UIFont.familyNames.sorted() {
            print("- \(family)")
            for name in UIFont.fontNames(forFamilyName: family).sorted() {
                print("  • \(name)")
            }
        }
        #endif
    }
}

// SwiftUI view that checks fonts on appear (add to development menu)
struct FontDebugView: View {
    @State private var futuraPTFontsLoaded = false
    
    var body: some View {
        List {
            Section(header: Text("Font Registry Status")) {
                ForEach(checkFontStatus().sorted { $0.key < $1.key }, id: \.key) { fontName, isLoaded in
                    HStack {
                        Text(fontName)
                        Spacer()
                        if isLoaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Section(header: Text("Sample Text")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Futura PT Book")
                        .font(.custom("FuturaPT-Book", size: 16, relativeTo: .body)
                    
                    Text("Futura PT Medium")
                        .font(.custom("FuturaPT-Medium", size: 16, relativeTo: .body)
                    
                    Text("Futura PT Demi")
                        .font(.custom("FuturaPT-Demi", size: 16, relativeTo: .body)
                    
                    Text("Futura PT Bold")
                        .font(.custom("FuturaPT-Bold", size: 16, relativeTo: .body)
                }
                .padding()
            }
        }
        .navigationTitle("Font Debug")
        .onAppear {
            FontRegistryChecker.checkFonts()
        }
    }
    
    // Helper method to check status of fonts
    private func checkFontStatus() -> [String: Bool] {
        let fontsToCheck = [
            "Montserrat-Regular",
            "Montserrat-Bold",
            "Montserrat-SemiBold",
            "RobotoMono-Medium",
            "FuturaPT-Book",
            "FuturaPT-Medium",
            "FuturaPT-Demi", 
            "FuturaPT-Bold"
        ]
        
        var status = [String: Bool]()
        for fontName in fontsToCheck {
            status[fontName] = UIFont(name: fontName, size: 16) != nil
        }
        
        return status
    }
} 