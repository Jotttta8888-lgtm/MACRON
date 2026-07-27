import Foundation

class FinanceTracker: ObservableObject {
    static let shared = FinanceTracker()
    @Published var monthlyTotal: Double = 0.0
    @Published var subscriptions: [String] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/finance_db.json"
    
    struct Transaction: Codable {
        let id = UUID()
        let description: String
        let amount: Double
        let category: String
        let date: Date
    }
    
    private var transactions: [Transaction] = []
    
    func addTransaction(description: String, amount: Double, category: String) {
        let tx = Transaction(description: description, amount: amount, category: category, date: Date())
        transactions.append(tx)
        save()
        NotificationService.shared.send(title: "MACRON Finance", body: "Gasto registrado: $" + String(format: "%.0f", amount))
    }
    
    func parseBankPDF(_ path: String) {
        NotificationService.shared.send(title: "MACRON Finance", body: "Analisis de extracto iniciado (beta)")
    }
    
    func getMonthlyReport() -> String {
        let calendar = Calendar.current
        let thisMonth = transactions.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        monthlyTotal = thisMonth.reduce(0) { $0 + $1.amount }
        let byCategory = Dictionary(grouping: thisMonth, by: { $0.category }).mapValues { $0.reduce(0) { $0 + $1.amount } }
        let lines = byCategory.sorted { $0.value > $1.value }.map { $0.key + ": $" + String(format: "%.0f", $0.value) }
        return "Total mes: $" + String(format: "%.0f", monthlyTotal) + "\n" + lines.joined(separator: "\n")
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(transactions)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([Transaction].self, from: data) else { return }
        transactions = decoded
    }
}
