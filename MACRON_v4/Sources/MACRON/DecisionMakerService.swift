import Foundation

class DecisionMakerService {
    static let shared = DecisionMakerService()
    
    func randomChoice(from options: [String]) -> String {
        guard let choice = options.randomElement() else { return "Sin opciones" }
        return "MACRON eligio: " + choice
    }
    
    func weightedChoice(options: [(String, Int)]) -> String {
        var pool: [String] = []
        for (option, weight) in options {
            pool.append(contentsOf: Array(repeating: option, count: weight))
        }
        guard let choice = pool.randomElement() else { return "Sin opciones" }
        return "MACRON eligio (ponderado): " + choice
    }
    
    func rollDice(sides: Int = 6) -> String {
        return "Dado de " + String(sides) + " caras: " + String(Int.random(in: 1...sides))
    }
    
    func flipCoin() -> String {
        return Bool.random() ? "Cara" : "Cruz"
    }
}
