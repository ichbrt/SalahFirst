import SwiftUI

/// A khatim tessellation — the eight-pointed star built from a square and the
/// same square turned 45° — drawn as a very low-contrast field.
///
/// Drawn rather than shipped as an image so it stays crisp at any size, adapts
/// to light and dark automatically, and carries no licensing question.
///
/// This is the whole of the app's ornament, and it is deliberately quiet: the
/// brief asked for calm and for none of the mosque-clipart look that dates
/// religious apps. Geometry is the oldest and most restrained part of Islamic
/// visual tradition, which lets the app read as what it is without shouting.
public struct GirihPattern: View {

    private let cell: CGFloat
    private let lineWidth: CGFloat
    private let opacity: Double

    public init(cell: CGFloat = 52, lineWidth: CGFloat = 0.9, opacity: Double = 1) {
        self.cell = cell
        self.lineWidth = lineWidth
        self.opacity = opacity
    }

    public var body: some View {
        Canvas { context, size in
            var path = Path()
            let radius = cell * 0.34
            let diagonal = radius * 1.414

            var y: CGFloat = 0
            while y <= size.height + cell {
                var x: CGFloat = 0
                while x <= size.width + cell {
                    path.addRect(
                        CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    )
                    path.move(to: CGPoint(x: x, y: y - diagonal))
                    path.addLine(to: CGPoint(x: x + diagonal, y: y))
                    path.addLine(to: CGPoint(x: x, y: y + diagonal))
                    path.addLine(to: CGPoint(x: x - diagonal, y: y))
                    path.closeSubpath()
                    x += cell
                }
                y += cell
            }

            context.stroke(path, with: .color(Theme.Palette.accent), lineWidth: lineWidth)
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

public extension View {
    /// The app's screen surface: the background colour with the pattern laid
    /// over it, strongest at the top and gone by the time the eye reaches the
    /// content that matters.
    ///
    /// Colour and pattern live in one modifier on purpose. Applied as two
    /// separate `.background` calls, the later one lands *behind* the earlier —
    /// which silently painted the surface straight over the pattern twice
    /// during development.
    func patternedBackground(fadeHeight: CGFloat = 520) -> some View {
        background(alignment: .top) {
            ZStack(alignment: .top) {
                Theme.Palette.background
                GirihPattern(opacity: 0.22)
                    .frame(height: fadeHeight)
                    .mask(
                        LinearGradient(
                            colors: [.black, .black.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .ignoresSafeArea()
        }
    }
}
