import Foundation
import SwiftUI
import PencilKit
enum GameMode {
    case drawing
    case math
}

class GameState: ObservableObject {
    @Published var isGameActive = false
    @Published var currentMode: GameMode = .drawing
    @Published var score = 0
    @Published var currentPrompt = ""
    @Published var canvasView = PKCanvasView()
    @Published var showFeedback = false
    @Published var feedback = ""
    @Published var drawing = PKDrawing()
    
    // Drawing mode prompts
    let drawingPrompts = ["circle", "square", "triangle", "star", "heart", "arrow"]

    
    func startNewGame(mode: GameMode) {
        currentMode = mode
        isGameActive = true
        score = 0
        generateNewPrompt()
    }
    
    func generateNewPrompt() {
        clearCanvas()
        if currentMode == .drawing {
            currentPrompt = drawingPrompts.randomElement() ?? "cat"
        } else {
            generateMathProblem()
        }
    }
    
    func generateMathProblem() {
        let operations = ["+", "-", "×"]
        var result = 100
        var num1 = 0, num2 = 0
        var operation = "+"

        while result > 9 {
            num1 = Int.random(in: 1...9)
            num2 = Int.random(in: 1...9)
            operation = operations.randomElement() ?? "+"
            
            switch operation {
            case "+": result = num1 + num2
            case "-": result = num1 - num2
            case "×": result = num1 * num2
            default: result = 100
            }
        }
        
        currentPrompt = "\(num1) \(operation) \(num2) = ?"
    }

    
    func clearCanvas() {
        // We'll handle clearing in the DrawingCanvas view
        canvasView = PKCanvasView() // Keep this for compatibility
    }
    
    func submitDrawing() {
        showFeedback = true
        if currentMode == .drawing {
            feedback = "Drawing submitted! ML recognition coming soon!"
            score += 10
        } else {
            feedback = "Number recognition coming soon!"
        }
        
        // Auto-generate new prompt after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showFeedback = false
            self.generateNewPrompt()
        }
    }
} 
