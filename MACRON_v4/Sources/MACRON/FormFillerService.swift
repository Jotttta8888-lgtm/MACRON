import Foundation
import AppKit

class FormFillerService: ObservableObject {
    static let shared = FormFillerService()
    @Published var profiles: [FormProfile] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/form_profiles.json"
    
    struct FormProfile: Identifiable, Codable {
        var id = UUID()
        let name: String
        let firstName: String
        let lastName: String
        let email: String
        let phone: String
        let address: String
        let city: String
        let country: String
        let zip: String
    }
    
    func createProfile(name: String, firstName: String, lastName: String, email: String, phone: String, address: String, city: String, country: String, zip: String) {
        let profile = FormProfile(name: name, firstName: firstName, lastName: lastName, email: email, phone: phone, address: address, city: city, country: country, zip: zip)
        profiles.append(profile)
        save()
    }
    
    func fillForm(profileId: UUID) -> [String: String] {
        guard let profile = profiles.first(where: { $0.id == profileId }) else { return [:] }
        return [
            "firstName": profile.firstName,
            "lastName": profile.lastName,
            "email": profile.email,
            "phone": profile.phone,
            "address": profile.address,
            "city": profile.city,
            "country": profile.country,
            "zip": profile.zip,
            "fullName": profile.firstName + " " + profile.lastName
        ]
    }
    
    func generateFakeData() -> [String: String] {
        let firstNames = ["Juan", "Maria", "Carlos", "Ana", "Luis", "Sofia"]
        let lastNames = ["Garcia", "Rodriguez", "Martinez", "Lopez", "Gonzalez"]
        let domains = ["gmail.com", "yahoo.com", "outlook.com", "macron.ai"]
        let fn = firstNames.randomElement()!
        let ln = lastNames.randomElement()!
        let email = fn.lowercased() + "." + ln.lowercased() + String(Int.random(in: 1...999)) + "@" + domains.randomElement()!
        return [
            "firstName": fn,
            "lastName": ln,
            "email": email,
            "phone": "+1-555-" + String(format: "%04d", Int.random(in: 1000...9999)),
            "address": String(Int.random(in: 100...9999)) + " " + ["Main St", "Oak Ave", "Park Rd"].randomElement()!,
            "city": ["New York", "Los Angeles", "Chicago", "Miami"].randomElement()!,
            "country": "USA",
            "zip": String(format: "%05d", Int.random(in: 10000...99999))
        ]
    }
    
    func copyToClipboard(profileId: UUID) {
        let data = fillForm(profileId: profileId)
        let text = data.map { $0.key + ": " + $0.value }.joined(separator: "\\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        NotificationService.shared.send(title: "MACRON Forms", body: "Datos copiados al portapapeles")
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(profiles)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([FormProfile].self, from: data) else { return }
        profiles = decoded
    }
}
