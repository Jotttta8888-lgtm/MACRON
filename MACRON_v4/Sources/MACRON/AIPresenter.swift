import Foundation
import AppKit

public final class AIPresenter: @unchecked Sendable {
    public static let shared = AIPresenter()
    
    public struct Slide: Sendable {
        public let title: String
        public let bullets: [String]
        public let notes: String
    }
    
    private init() {}
    
    public func createPresentation(topic: String, slidesCount: Int = 5) async -> [Slide] {
        let prompt = "Crea una presentacion sobre: " + topic
            + "\n\nGenera exactamente " + String(slidesCount) + " slides."
            + "Cada slide debe tener un titulo y 3-5 bullet points."
            + "Responde en este formato exacto:\n"
            + "SLIDE 1\nTitulo: [titulo]\n- [bullet 1]\n- [bullet 2]\n- [bullet 3]\n\n"
            + "SLIDE 2\n..."
        
        let response = await LLMConnector.shared.generate(prompt: prompt)
        return parseSlides(from: response, fallbackTopic: topic)
    }
    
    public func createInKeynote(topic: String, slidesCount: Int = 5) async -> String {
        let slides = await createPresentation(topic: topic, slidesCount: slidesCount)
        
        // Generar AppleScript para crear Keynote
        var script = "tell application \"Keynote\"\n"
        script += "    activate\n"
        script += "    set newDoc to make new document\n"
        script += "    tell newDoc\n"
        
        for (index, slide) in slides.enumerated() {
            if index == 0 {
                // Primer slide: titulo
                script += "        set the title of the current slide to \"" + escapeAppleScript(slide.title) + "\"\n"
            } else {
                script += "        set newSlide to make new slide\n"
                script += "        tell newSlide\n"
                script += "            set the title to \"" + escapeAppleScript(slide.title) + "\"\n"
                script += "            set the body to \"" + escapeAppleScript(slide.bullets.joined(separator: "\\n")) + "\"\n"
                script += "        end tell\n"
            }
        }
        
        script += "    end tell\n"
        script += "end tell\n"
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        try? task.run()
        task.waitUntilExit()
        
        var result = "Presentacion creada en Keynote: " + topic + "\n"
        result += String(slides.count) + " slides generados.\n\n"
        for slide in slides {
            result += "• " + slide.title + "\n"
        }
        return result
    }
    
    public func quickOutline(topic: String) async -> String {
        let prompt = "Crea un outline de presentacion sobre: " + topic
            + "\n\nResponde con solo los titulos de los slides, uno por linea."
        let response = await LLMConnector.shared.generate(prompt: prompt)
        return response
    }
    
    // MARK: - Private
    
    private func parseSlides(from text: String, fallbackTopic: String) -> [Slide] {
        var slides: [Slide] = []
        let lines = text.components(separatedBy: .newlines)
        var currentTitle = ""
        var currentBullets: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Titulo:") || trimmed.hasPrefix("Title:") {
                if !currentTitle.isEmpty {
                    slides.append(Slide(title: currentTitle, bullets: currentBullets, notes: ""))
                }
                currentTitle = trimmed.replacingOccurrences(of: "Titulo:", with: "").replacingOccurrences(of: "Title:", with: "").trimmingCharacters(in: .whitespaces)
                currentBullets = []
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                currentBullets.append(trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces).description)
            } else if trimmed.hasPrefix("SLIDE") && !currentTitle.isEmpty {
                slides.append(Slide(title: currentTitle, bullets: currentBullets, notes: ""))
                currentTitle = ""
                currentBullets = []
            }
        }
        
        if !currentTitle.isEmpty {
            slides.append(Slide(title: currentTitle, bullets: currentBullets, notes: ""))
        }
        
        // Fallback si el parsing falla
        if slides.isEmpty {
            slides.append(Slide(title: fallbackTopic, bullets: ["Generado por MACRON AI"], notes: ""))
        }
        
        return slides
    }
    
    private func escapeAppleScript(_ text: String) -> String {
        return text.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
