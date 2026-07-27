import Foundation

class RecipeManagerService: ObservableObject {
    static let shared = RecipeManagerService()
    @Published var recipes: [Recipe] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/recipes.json"
    
    struct Recipe: Identifiable, Codable {
        var id = UUID()
        let name: String
        let ingredients: [String]
        let instructions: String
        let prepTime: Int
        let tags: [String]
    }
    
    func addRecipe(name: String, ingredients: [String], instructions: String, prepTime: Int, tags: [String] = []) {
        let recipe = Recipe(name: name, ingredients: ingredients, instructions: instructions, prepTime: prepTime, tags: tags)
        recipes.append(recipe)
        save()
        NotificationService.shared.send(title: "MACRON Recipes", body: "Receta guardada: " + name)
    }
    
    func searchByIngredient(_ ingredient: String) -> [Recipe] {
        let lower = ingredient.lowercased()
        return recipes.filter { $0.ingredients.contains(where: { $0.lowercased().contains(lower) }) }
    }
    
    func generateShoppingList() -> [String] {
        var list: Set<String> = []
        for recipe in recipes {
            recipe.ingredients.forEach { list.insert($0) }
        }
        return Array(list).sorted()
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(recipes)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([Recipe].self, from: data) else { return }
        recipes = decoded
    }
}
