import SwiftUI

struct DrawingCanvas: View {
    @Binding var lines: [[CGPoint]]
    @Binding var currentLine: [CGPoint]
    @Binding var debugText: String

    var body: some View {
        VStack {
            Text(debugText)
                .font(.caption)
                .foregroundColor(.blue)

            ZStack {
                Color.white
                    .border(Color.gray, width: 2)
                    .frame(height: 300)
                    .contentShape(Rectangle())

                // Draw completed lines
                ForEach(0..<lines.count, id: \.self) { lineIndex in
                    Path { path in
                        let points = lines[lineIndex]
                        if let firstPoint = points.first {
                            path.move(to: firstPoint)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(Color.black, lineWidth: 3)
                }

                // Draw current line
                Path { path in
                    if let firstPoint = currentLine.first {
                        path.move(to: firstPoint)
                        for point in currentLine.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.black, lineWidth: 3)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        debugText = "Drawing at: \(value.location)"
                        currentLine.append(value.location)
                    }
                    .onEnded { _ in
                        debugText = "Finished drawing"
                        if !currentLine.isEmpty {
                            lines.append(currentLine)
                            currentLine = []
                        }
                    }
            )
        }
        .padding()
    }
}
