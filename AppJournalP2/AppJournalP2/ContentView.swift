//
//  ContentView.swift
//  AppJournalP2
//
//  Created by Andy Zhu on 4/18/25.
//

import SwiftUI
import CoreML

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        NavigationView {
            if gameState.isGameActive {
                GameView(gameState: gameState)
            } else {
                VStack(spacing: 30) {
                    Text("SketchQuiz")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("Draw and Learn!")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Game mode buttons
                    VStack(spacing: 20) {
                        Button(action: {
                            gameState.startNewGame(mode: .drawing)
                        }) {
                            GameModeButton(
                                title: "Drawing Mode",
                                subtitle: "Draw objects and let AI guess",
                                icon: "pencil",
                                color: .blue
                            )
                        }
                        
                        Button(action: {
                            gameState.startNewGame(mode: .math)
                        }) {
                            GameModeButton(
                                title: "Math Mode",
                                subtitle: "Solve math problems by drawing numbers",
                                icon: "number",
                                color: .green
                            )
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct GameModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}


struct GameView: View {
    @ObservedObject var gameState: GameState
    
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    @State private var debugText: String = "No interaction yet"
    
    func evaluateMath(prompt: String) -> String {
        print("Evaluating prompt: \(prompt)")

        // Expects: "5 + 3 = ?"
        let parts = prompt.split(separator: " ")
        guard parts.count >= 3 else {
            print("Prompt parsing failed — not enough parts")
            return "?"
        }

        let num1 = Int(parts[0]) ?? -1
        let op = String(parts[1])
        let num2 = Int(parts[2]) ?? -1

        var result: Int = -999
        switch op {
        case "+": result = num1 + num2
        case "-": result = num1 - num2
        case "×": result = num1 * num2
        default:
            print("Unknown operation: \(op)")
            return "?"
        }

        return String(result)
    }



    var body: some View {
        VStack {
            Text("Current Score: \(gameState.score)")
                .font(.headline)
            
            Text("Draw: \(gameState.currentPrompt)")
            if gameState.showFeedback {
                Text(gameState.feedback)
                    .font(.headline)
                    .foregroundColor(.purple)
                    .transition(.opacity)
                    .padding(.bottom, 10)
            }
            
            // Drawing canvas placeholder
            DrawingCanvas(
                lines: $lines,
                currentLine: $currentLine,
                debugText: $debugText
            )

            
            HStack {
                Button("Clear") {
                    lines = []
                    currentLine = []
                    debugText = "Canvas cleared"
                }
                .buttonStyle(.bordered)

                Button("Submit") {
                    let image = renderDrawingToImage(lines: lines)
                    
                    if let pixelBuffer = imageToCVPixelBuffer(image) {
                        if gameState.currentMode == .math {
                            do {
                                let model = try MNISTClassifier(configuration: MLModelConfiguration())
                                let prediction = try model.prediction(image: pixelBuffer)
                                let predictedDigit = prediction.classLabel
                                debugText = "Predicted digit: \(predictedDigit)"
                                
                                let correctAnswer = evaluateMath(prompt: gameState.currentPrompt)
                                debugText += " | Expected: \(correctAnswer)"
                                
                                if let correctAnswerInt = Int64(correctAnswer), predictedDigit == correctAnswerInt {
                                    gameState.score += 10
                                    gameState.feedback = "✅ Correct!"
                                } else {
                                    gameState.feedback = "❌ Try again. Answer: \(correctAnswer)"
                                }
                            } catch {
                                debugText = "MNIST prediction failed: \(error.localizedDescription)"
                                gameState.feedback = "Prediction error."
                            }
                        } else if gameState.currentMode == .drawing {
                            do {
                                let model = try UpdatableDrawingClassifier(configuration: MLModelConfiguration())
                                let prediction = try model.prediction(drawing: pixelBuffer)
                                let predictedLabel = prediction.label.lowercased()
                                let actualLabel = gameState.currentPrompt.lowercased()
                                
                                debugText = "Drawing predicted: \(predictedLabel)"
                                
                                if predictedLabel == actualLabel {
                                    gameState.score += 10
                                    gameState.feedback = "🎉 Great drawing of a \(actualLabel)!"
                                } else {
                                    gameState.feedback = "Hmm... I saw a \(predictedLabel). Try again!"
                                }
                            } catch {
                                debugText = "DrawingClassifier prediction failed: \(error.localizedDescription)"
                                gameState.feedback = "Prediction error."
                            }
                        }
                        
                        // Show feedback briefly
                        gameState.showFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            gameState.showFeedback = false
                            gameState.generateNewPrompt()
                        }
                    } else {
                        debugText = "❌ Failed to convert drawing to pixel buffer."
                    }
                }
                .buttonStyle(.borderedProminent)
 //end of button submit


                .buttonStyle(.borderedProminent)
            }

            
            Button("End Game") {
                gameState.isGameActive = false
            }
            .padding(.top)
        }
    }
}

#Preview {
    ContentView()
}
