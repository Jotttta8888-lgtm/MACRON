import Foundation

class UnitConverterProService {
    static let shared = UnitConverterProService()
    
    let categories: [String: [String: Double]] = [
        "length": ["m": 1.0, "km": 0.001, "cm": 100, "mm": 1000, "mi": 0.000621371, "yd": 1.09361, "ft": 3.28084, "in": 39.3701],
        "mass": ["kg": 1.0, "g": 1000, "mg": 1000000, "lb": 2.20462, "oz": 35.274, "st": 0.157473],
        "temperature": ["c": 1.0, "f": 1.0, "k": 1.0],
        "speed": ["mps": 1.0, "kph": 3.6, "mph": 2.23694, "knot": 1.94384],
        "pressure": ["pa": 1.0, "kpa": 0.001, "bar": 0.00001, "atm": 0.00000986923, "psi": 0.000145038],
        "data": ["b": 1.0, "kb": 0.000976562, "mb": 9.53674e-7, "gb": 9.31323e-10, "tb": 9.09495e-13]
    ]
    
    func convert(value: Double, from: String, to: String, category: String) -> String {
        guard let units = categories[category.lowercased()] else { return "Categoria no valida" }
        guard units[from.lowercased()] != nil, units[to.lowercased()] != nil else {
            return "Unidad no valida"
        }
        var result: Double
        if category.lowercased() == "temperature" {
            result = convertTemperature(value: value, from: from.lowercased(), to: to.lowercased())
        } else {
            let base = value / (units[from.lowercased()] ?? 1.0)
            result = base * (units[to.lowercased()] ?? 1.0)
        }
        return String(format: "%.4f %@ = %.4f %@", value, from, result, to)
    }
    
    private func convertTemperature(value: Double, from: String, to: String) -> Double {
        var celsius: Double
        switch from {
        case "f": celsius = (value - 32) * 5/9
        case "k": celsius = value - 273.15
        default: celsius = value
        }
        switch to {
        case "f": return celsius * 9/5 + 32
        case "k": return celsius + 273.15
        default: return celsius
        }
    }
    
    func getCategories() -> [String] {
        return Array(categories.keys).sorted()
    }
    
    func getUnits(for category: String) -> [String] {
        guard let cat = categories[category.lowercased()] else { return [] }
        return Array(cat.keys).sorted()
    }
}
