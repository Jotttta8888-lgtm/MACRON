import Foundation

class SpreadsheetAIService: ObservableObject {
    static let shared = SpreadsheetAIService()
    
    func readCSV(path: String) -> [[String]]? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.map { $0.components(separatedBy: ",") }
    }
    
    func detectAnomalies(data: [[String]]) -> [String] {
        guard data.count > 1 else { return [] }
        var anomalies: [String] = []
        for col in 0..<data[0].count {
            var values: [Double] = []
            for row in 1..<data.count {
                if let val = Double(data[row][col]) {
                    values.append(val)
                }
            }
            guard values.count > 2 else { continue }
            let avg = values.reduce(0, +) / Double(values.count)
            let variance = values.map { pow($0 - avg, 2) }.reduce(0, +) / Double(values.count)
            let stdDev = sqrt(variance)
            for (i, val) in values.enumerated() {
                if abs(val - avg) > 2 * stdDev {
                    anomalies.append("Fila \(i+2), Col \(col+1): \(val) es anomalia (media: \(String(format: "%.2f", avg)))")
                }
            }
        }
        return anomalies
    }
    
    func suggestFormula(for column: [Double]) -> String {
        let sum = column.reduce(0, +)
        let avg = sum / Double(column.count)
        let max = column.max() ?? 0
        let min = column.min() ?? 0
        return "SUMA=\(String(format: "%.2f", sum)), PROMEDIO=\(String(format: "%.2f", avg)), MAX=\(String(format: "%.2f", max)), MIN=\(String(format: "%.2f", min))"
    }
    
    func generateChartData(data: [[String]], labelColumn: Int, valueColumn: Int) -> [String: Double] {
        var result: [String: Double] = [:]
        for row in 1..<data.count {
            let label = data[row][labelColumn]
            if let val = Double(data[row][valueColumn]) {
                result[label] = val
            }
        }
        return result
    }
    
    func exportToJSON(csvPath: String, jsonPath: String) -> Bool {
        guard let rows = readCSV(path: csvPath), let headers = rows.first else { return false }
        var objects: [[String: String]] = []
        for row in rows.dropFirst() {
            var obj: [String: String] = [:]
            for (i, header) in headers.enumerated() where i < row.count {
                obj[header] = row[i]
            }
            objects.append(obj)
        }
        let data = try? JSONSerialization.data(withJSONObject: objects, options: .prettyPrinted)
        try? data?.write(to: URL(fileURLWithPath: jsonPath))
        return data != nil
    }
}
