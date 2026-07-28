import Foundation

class StockPortfolioService: ObservableObject {
    static let shared = StockPortfolioService()
    @Published var holdings: [StockHolding] = []
    @Published var watchlist: [String] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/portfolio.json"
    
    struct StockHolding: Identifiable, Codable {
        var id = UUID()
        let symbol: String
        let shares: Double
        let avgPrice: Double
        var currentPrice: Double = 0
    }
    
    func addHolding(symbol: String, shares: Double, avgPrice: Double) {
        let holding = StockHolding(symbol: symbol.uppercased(), shares: shares, avgPrice: avgPrice)
        holdings.append(holding)
        save()
        NotificationService.shared.send(title: "MACRON Stocks", body: "Añadido: " + symbol.uppercased())
    }
    
    func updatePrice(symbol: String, price: Double) {
        guard let idx = holdings.firstIndex(where: { $0.symbol == symbol.uppercased() }) else { return }
        holdings[idx].currentPrice = price
    }
    
    func getPnL(_ holding: StockHolding) -> Double {
        return (holding.currentPrice - holding.avgPrice) * holding.shares
    }
    
    func getTotalValue() -> Double {
        return holdings.reduce(0) { $0 + ($1.currentPrice * $1.shares) }
    }
    
    func getTotalPnL() -> Double {
        return holdings.reduce(0) { $0 + getPnL($1) }
    }
    
    func fetchPrice(symbol: String, completion: @escaping (Double?) -> Void) {
        let urlStr = "https://query1.finance.yahoo.com/v8/finance/chart/" + symbol.uppercased()
        guard let url = URL(string: urlStr) else { completion(nil); return }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let chart = json["chart"] as? [String: Any],
                  let result = chart["result"] as? [[String: Any]],
                  let meta = result.first?["meta"] as? [String: Any],
                  let price = meta["regularMarketPrice"] as? Double else {
                completion(nil)
                return
            }
            DispatchQueue.main.async { completion(price) }
        }
        task.resume()
    }
    
    func addToWatchlist(_ symbol: String) {
        let upper = symbol.uppercased()
        if !watchlist.contains(upper) {
            watchlist.append(upper)
        }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(holdings)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([StockHolding].self, from: data) else { return }
        holdings = decoded
    }
}
