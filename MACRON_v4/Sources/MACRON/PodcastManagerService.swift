import Foundation

class PodcastManagerService: ObservableObject {
    static let shared = PodcastManagerService()
    @Published var episodes: [PodcastEpisode] = []
    
    struct PodcastEpisode: Identifiable {
        let id = UUID()
        let title: String
        let url: String
        let pubDate: String
    }
    
    func fetchEpisodes(feedURL: String = "https://feeds.megaphone.fm/replyall") {
        guard let url = URL(string: feedURL) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let xml = String(data: data, encoding: .utf8) else { return }
            let titles = self.extractTitles(from: xml)
            DispatchQueue.main.async {
                self.episodes = titles.prefix(10).map { PodcastEpisode(title: $0, url: "", pubDate: "") }
            }
        }
        task.resume()
    }
    
    private func extractTitles(from xml: String) -> [String] {
        var results: [String] = []
        let pattern = "<title>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: xml, range: NSRange(location: 0, length: xml.utf16.count))
        for match in matches {
            if let range = Range(match.range(at: 1), in: xml) {
                results.append(String(xml[range]))
            }
        }
        return results
    }
}
