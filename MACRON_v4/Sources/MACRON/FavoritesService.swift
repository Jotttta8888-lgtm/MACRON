import Foundation

class FavoritesService: ObservableObject {
    @Published var favorites: [String] = []
    private let key = "macron_favorites"

    init() { load() }

    func add(_ command: String) {
        if !favorites.contains(command) {
            favorites.append(command)
            save()
        }
    }

    func remove(_ command: String) {
        favorites.removeAll { $0 == command }
        save()
    }

    private func save() {
        UserDefaults.standard.set(favorites, forKey: key)
    }

    private func load() {
        favorites = UserDefaults.standard.stringArray(forKey: key) ?? []
    }
}
