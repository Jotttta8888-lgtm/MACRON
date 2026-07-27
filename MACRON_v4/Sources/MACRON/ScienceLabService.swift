import Foundation

class ScienceLabService {
    static let shared = ScienceLabService()
    
    let constants: [String: Double] = [
        "pi": Double.pi,
        "e": exp(1.0),
        "c": 299792458,
        "G": 6.67430e-11,
        "h": 6.62607015e-34,
        "Na": 6.02214076e23,
        "k": 1.380649e-23,
        "g": 9.80665
    ]
    
    func calculate(_ expression: String) -> String {
        let mathExpr = expression
            .replacingOccurrences(of: "sin(", with: "sin(Double.pi/180*")
            .replacingOccurrences(of: "cos(", with: "cos(Double.pi/180*")
            .replacingOccurrences(of: "tan(", with: "tan(Double.pi/180*")
            .replacingOccurrences(of: "sqrt(", with: "sqrt(")
            .replacingOccurrences(of: "log(", with: "log10(")
            .replacingOccurrences(of: "ln(", with: "log(")
            .replacingOccurrences(of: "^", with: "**")
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        task.arguments = ["-c", "import math; print(" + mathExpr + ")"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Error"
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func convert(value: Double, from unit: String, to target: String) -> String {
        let conversions: [String: [String: Double]] = [
            "m": ["km": 0.001, "cm": 100, "mm": 1000, "ft": 3.28084, "in": 39.3701],
            "kg": ["g": 1000, "lb": 2.20462, "oz": 35.274],
            "c": ["f": 1.8, "k": 1.0],
            "l": ["ml": 1000, "gal": 0.264172]
        ]
        guard let fromMap = conversions[unit.lowercased()], let factor = fromMap[target.lowercased()] else {
            return "Conversion no soportada"
        }
        var result = value * factor
        if unit.lowercased() == "c" && target.lowercased() == "f" { result = value * 1.8 + 32 }
        if unit.lowercased() == "c" && target.lowercased() == "k" { result = value + 273.15 }
        return String(format: "%.4f %@ = %.4f %@", value, unit, result, target)
    }
    
    func getConstant(_ name: String) -> String {
        guard let val = constants[name.lowercased()] else { return "Constante no encontrada" }
        return name + " = " + String(format: "%.6e", val)
    }
}
