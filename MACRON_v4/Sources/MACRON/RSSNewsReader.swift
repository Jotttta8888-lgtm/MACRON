import Foundation

class RSSNewsReader: ObservableObject {
    static let shared = RSSNewsReader()
    @Published var headlines: [NewsItem] = []
    
    struct NewsItem: Identifiable {
        let id = UUID()
        let title: String
        let link: String
        let source: String
    }
    
    func fetchFeed(url: String, source: String) {
        guard let urlObj = URL(string: url) else { return }
        let task = URLSession.shared.dataTask(with: urlObj) { data, _, _ in
            guard let data = data, let xml = String(data: data, encoding: .utf8) else { return }
            let titles = self.extractTitles(from: xml)
            DispatchQueue.main.async {
                for title in titles.prefix(5) {
                    self.headlines.append(NewsItem(title: title, link: "", source: source))
                }
            }
        }
        task.resume()
    }
    
    private func extractTitles(from xml: String) -> [String] {
        var titles: [String] = []
        let pattern = "<title>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: xml, range: NSRange(location: 0, length: xml.utf16.count))
        for match in matches {
            if let range = Range(match.range(at: 1), in: xml) {
                titles.append(String(xml[range]))
            }
        }
        return titles
    }
}
