import Foundation

class CalculatorService {
    static let shared = CalculatorService()
    
    func calculate(_ expression: String) -> String {
        let sanitized = expression.filter { "0123456789.+-*/()^% ".contains($0) }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        task.arguments = ["-c", "print(" + sanitized + ")"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let result = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Error"
        return result
    }
    
    func convert(value: Double, fromUnit: String, toUnit: String) -> String {
        let conversions: [String: [String: Double]] = [
            "km": ["mi": 0.621371, "m": 1000],
            "mi": ["km": 1.60934, "m": 1609.34],
            "kg": ["lb": 2.20462, "g": 1000],
            "lb": ["kg": 0.453592, "g": 453.592],
            "usd": ["cop": 3900, "eur": 0.85],
            "eur": ["cop": 4600, "usd": 1.18],
            "cop": ["usd": 0.000256, "eur": 0.000217]
        ]
        guard let fromConvs = conversions[fromUnit.lowercased()],
              let rate = fromConvs[toUnit.lowercased()] else { return "Conversion no soportada" }
        let result = value * rate
        return String(format: "%.2f", result) + " " + toUnit
    }
}
