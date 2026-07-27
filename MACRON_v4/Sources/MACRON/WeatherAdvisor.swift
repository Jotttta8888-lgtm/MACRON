import Foundation

class WeatherAdvisor: ObservableObject {
    static let shared = WeatherAdvisor()
    @Published var currentWeather = "Desconocido"
    @Published var outfitAdvice = ""
    
    func checkWeather() {
        let script = "tell application \"Weather\" to return name of current location & \" | \" & temperature of current location & \"C | \" & condition of current location"
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return }
        let result = appleScript.executeAndReturnError(&errorInfo)
        if let error = errorInfo {
            if let fallback = shell("curl -s wttr.in/?format=%C+%t") {
                currentWeather = fallback
                outfitAdvice = generateAdvice(fallback)
            }
            return
        }
        if let weather = result.stringValue {
            currentWeather = weather
            outfitAdvice = generateAdvice(weather)
        }
    }
    
    private func generateAdvice(_ weather: String) -> String {
        let lower = weather.lowercased()
        if lower.contains("rain") || lower.contains("lluvia") { return "Lleva paraguas y chaqueta impermeable" }
        if lower.contains("snow") || lower.contains("nieve") { return "Abrigate bien, botas y bufanda" }
        if lower.contains("sun") || lower.contains("soleado") || lower.contains("clear") { return "Dia soleado, gafas de sol recomendadas" }
        if lower.contains("cloud") || lower.contains("nublado") { return "Dia nublado, lleva una chaqueta ligera" }
        if lower.contains("hot") || lower.contains("calor") { return "Mucho calor, ropa ligera y hidratacion" }
        return "Revisa el clima antes de salir"
    }
    
    private func shell(_ command: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", command]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
