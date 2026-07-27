import Foundation

class DataVisualizerService {
    static let shared = DataVisualizerService()
    
    func generateBarChart(data: [String: Double]) -> String {
        let maxVal = data.values.max() ?? 1
        var lines: [String] = []
        for (key, val) in data.sorted(by: { $0.value > $1.value }) {
            let barCount = Int((val / maxVal) * 20)
            let bar = String(repeating: "█", count: barCount)
            lines.append(key.padding(toLength: 12, withPad: " ", startingAt: 0) + " " + bar + " " + String(format: "%.1f", val))
        }
        return lines.joined(separator: "\n")
    }
    
    func generatePieChart(data: [String: Double]) -> String {
        let total = data.values.reduce(0, +)
        var lines: [String] = []
        for (key, val) in data.sorted(by: { $0.value > $1.value }) {
            let pct = (val / total) * 100
            lines.append(key + ": " + String(format: "%.1f", pct) + "%")
        }
        return lines.joined(separator: "\n")
    }
}
