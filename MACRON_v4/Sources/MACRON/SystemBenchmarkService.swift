import Foundation

class SystemBenchmarkService: ObservableObject {
    static let shared = SystemBenchmarkService()
    @Published var lastScore: Double = 0
    @Published var history: [BenchmarkResult] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/benchmarks.json"
    
    struct BenchmarkResult: Identifiable, Codable {
        var id = UUID()
        let date: Date
        let cpuScore: Double
        let memoryScore: Double
        let diskScore: Double
        let totalScore: Double
    }
    
    func runBenchmark() {
        let cpu = benchmarkCPU()
        let mem = benchmarkMemory()
        let disk = benchmarkDisk()
        let total = (cpu + mem + disk) / 3.0
        
        let result = BenchmarkResult(date: Date(), cpuScore: cpu, memoryScore: mem, diskScore: disk, totalScore: total)
        history.append(result)
        lastScore = total
        save()
        NotificationService.shared.send(title: "MACRON Benchmark", body: String(format: "Score: %.0f", total))
    }
    
    private func benchmarkCPU() -> Double {
        let start = Date()
        var sum: Double = 0
        for i in 1...1000000 {
            sum += sqrt(Double(i))
        }
        let elapsed = Date().timeIntervalSince(start)
        return max(0, 10000 - elapsed * 1000)
    }
    
    private func benchmarkMemory() -> Double {
        let start = Date()
        var arr: [Int] = []
        for i in 0..<100000 {
            arr.append(i)
        }
        let elapsed = Date().timeIntervalSince(start)
        return max(0, 10000 - elapsed * 10000)
    }
    
    private func benchmarkDisk() -> Double {
        let start = Date()
        let path = NSHomeDirectory() + "/Documents/MACRON/bench_temp.txt"
        let data = String(repeating: "X", count: 1000000)
        try? data.write(toFile: path, atomically: true, encoding: .utf8)
        _ = try? String(contentsOfFile: path, encoding: .utf8)
        try? FileManager.default.removeItem(atPath: path)
        let elapsed = Date().timeIntervalSince(start)
        return max(0, 10000 - elapsed * 1000)
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(history)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([BenchmarkResult].self, from: data) else { return }
        history = decoded
    }
}
