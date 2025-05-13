import XCTest
import SwiftUI
@testable import PTChampion

class ColorSnapshotTests: XCTestCase {
    
    // A helper to render a grid of color swatches
    func renderColorGrid(colorScheme: ColorScheme = .light) -> UIImage {
        let colors: [(name: String, color: Color)] = [
            // Base colors
            ("cream", .cream),
            ("creamDark", .creamDark),
            ("creamLight", .creamLight),
            ("deepOps", .deepOps),
            ("brassGold", .brassGold),
            ("armyTan", .armyTan),
            ("oliveMist", .oliveMist),
            ("commandBlack", .commandBlack),
            ("tacticalGray", .tacticalGray),
            ("hunterGreen", .hunterGreen),
            ("border", .border),
            
            // Semantic colors
            ("background", .background),
            ("foreground", .foreground),
            ("primary", .primary),
            ("primaryForeground", .primaryForeground),
            ("secondary", .secondary),
            ("secondaryForeground", .secondaryForeground),
            ("muted", .muted),
            ("mutedForeground", .mutedForeground),
            ("accent", .accent),
            ("accentForeground", .accentForeground),
            ("card", .card),
            ("cardForeground", .cardForeground),
            
            // Status colors
            ("success", .success),
            ("warning", .warning),
            ("error", .error),
            ("info", .info),
            ("destructive", .destructive),
            ("destructiveForeground", .destructiveForeground)
        ]
        
        let columnsCount = 4
        let cellSize: CGFloat = 100
        let padding: CGFloat = 8
        
        let rowsCount = Int(ceil(Double(colors.count) / Double(columnsCount)))
        let width = CGFloat(columnsCount) * (cellSize + padding) + padding
        let height = CGFloat(rowsCount) * (cellSize + padding) + padding
        
        let colorGrid = ColorGrid(colors: colors, columns: columnsCount, cellSize: cellSize, padding: padding)
            .preferredColorScheme(colorScheme)
            .frame(width: width, height: height)
        
        let controller = UIHostingController(rootView: colorGrid)
        let view = controller.view!
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        view.backgroundColor = UIColor(Color.background)
        
        // Make sure the view is laid out
        view.layoutIfNeeded()
        
        // Create an image of the view
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
    }
    
    func testColorSnapshotsLightMode() {
        let image = renderColorGrid(colorScheme: .light)
        
        // Get snapshot folder
        let snapshotsFolder = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ColorSnapshots", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: snapshotsFolder,
                                               withIntermediateDirectories: true,
                                               attributes: nil)
        
        // Save the snapshot
        let snapshotURL = snapshotsFolder.appendingPathComponent("ColorPalette_Light.png")
        if let pngData = image.pngData() {
            try? pngData.write(to: snapshotURL)
            print("Color palette snapshot saved to: \(snapshotURL.path)")
        }
        
        // In a real test, we would compare against reference images
        // XCTAssertTrue(compareWithReferenceImage(image, named: "ColorPalette_Light"))
    }
    
    func testColorSnapshotsDarkMode() {
        let image = renderColorGrid(colorScheme: .dark)
        
        // Get snapshot folder
        let snapshotsFolder = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ColorSnapshots", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: snapshotsFolder,
                                               withIntermediateDirectories: true,
                                               attributes: nil)
        
        // Save the snapshot
        let snapshotURL = snapshotsFolder.appendingPathComponent("ColorPalette_Dark.png")
        if let pngData = image.pngData() {
            try? pngData.write(to: snapshotURL)
            print("Color palette snapshot saved to: \(snapshotURL.path)")
        }
        
        // In a real test, we would compare against reference images
        // XCTAssertTrue(compareWithReferenceImage(image, named: "ColorPalette_Dark"))
    }
}

// Helper view to render a grid of color swatches
struct ColorGrid: View {
    var colors: [(name: String, color: Color)]
    var columns: Int
    var cellSize: CGFloat
    var padding: CGFloat
    
    var body: some View {
        VStack(spacing: padding) {
            ForEach(0..<rowsCount, id: \.self) { row in
                HStack(spacing: padding) {
                    ForEach(0..<columnsInRow(row), id: \.self) { col in
                        let index = row * columns + col
                        ColorSwatch(name: colors[index].name, color: colors[index].color)
                            .frame(width: cellSize, height: cellSize)
                    }
                    if columnsInRow(row) < columns {
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .padding(padding)
        .background(Color.background)
    }
    
    private var rowsCount: Int {
        Int(ceil(Double(colors.count) / Double(columns)))
    }
    
    private func columnsInRow(_ row: Int) -> Int {
        let remainingColors = colors.count - row * columns
        return min(columns, remainingColors)
    }
}

// Color swatch component
struct ColorSwatch: View {
    var name: String
    var color: Color
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .aspectRatio(1, contentMode: .fit)
            
            Text(name)
                .font(.system(size: 12)
                .foregroundColor(.foreground)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
} 