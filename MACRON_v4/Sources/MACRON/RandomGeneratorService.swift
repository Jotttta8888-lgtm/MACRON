import Foundation

class RandomGeneratorService {
    static let shared = RandomGeneratorService()
    
    func generatePassword(length: Int = 16, includeSymbols: Bool = true) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        var chars = letters + numbers
        if includeSymbols { chars += symbols }
        return String((0..<length).map { _ in chars.randomElement()! })
    }
    
    func generateUUID() -> String {
        return UUID().uuidString
    }
    
    func generateRandomNumber(min: Int, max: Int) -> Int {
        return Int.random(in: min...max)
    }
    
    func generateFakeName() -> String {
        let first = ["James", "Maria", "Robert", "Jennifer", "Michael", "Linda", "William", "Patricia"]
        let last = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis"]
        return first.randomElement()! + " " + last.randomElement()!
    }
    
    func generateFakeEmail() -> String {
        let local = ["user", "admin", "test", "dev", "support", "info"]
        let domains = ["example.com", "test.org", "demo.net", "mail.io"]
        return local.randomElement()! + String(Int.random(in: 1...999)) + "@" + domains.randomElement()!
    }
    
    func generateHexColor() -> String {
        return String(format: "#%06X", Int.random(in: 0...0xFFFFFF))
    }
}
