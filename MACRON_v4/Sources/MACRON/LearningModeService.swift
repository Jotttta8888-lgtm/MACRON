import Foundation

class LearningModeService: ObservableObject {
    static let shared = LearningModeService()
    @Published var flashcards: [Flashcard] = []
    @Published var studyTimerActive = false
    @Published var studyTimeRemaining = 45 * 60
    private var timer: Timer?
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/flashcards.json"
    
    struct Flashcard: Identifiable, Codable {
        var id = UUID()
        let front: String
        let back: String
        let category: String
        var lastReviewed: Date?
        var interval: Int = 1
    }
    
    func addFlashcard(front: String, back: String, category: String = "General") {
        let card = Flashcard(front: front, back: back, category: category)
        flashcards.append(card)
        save()
    }
    
    func getDueCards() -> [Flashcard] {
        let now = Date()
        return flashcards.filter { card in
            guard let last = card.lastReviewed else { return true }
            let days = card.interval
            let due = Calendar.current.date(byAdding: .day, value: days, to: last) ?? now
            return now >= due
        }
    }
    
    func reviewCard(id: UUID, known: Bool) {
        guard let idx = flashcards.firstIndex(where: { $0.id == id }) else { return }
        flashcards[idx].lastReviewed = Date()
        flashcards[idx].interval = known ? min(flashcards[idx].interval * 2, 30) : 1
        save()
    }
    
    func startStudyTimer(minutes: Int = 45) {
        studyTimeRemaining = minutes * 60
        studyTimerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.studyTimeRemaining > 0 {
                self.studyTimeRemaining -= 1
            } else {
                self.studyTimerActive = false
                self.timer?.invalidate()
                NotificationService.shared.send(title: "MACRON Study", body: "Sesion de estudio completada")
            }
        }
    }
    
    func stopStudyTimer() {
        studyTimerActive = false
        timer?.invalidate()
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(flashcards)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([Flashcard].self, from: data) else { return }
        flashcards = decoded
    }
}
