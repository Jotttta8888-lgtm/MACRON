import Foundation

public final class ReasoningEngine: @unchecked Sendable {
    public static let shared = ReasoningEngine()
    public struct ReasoningStep: Identifiable, Sendable {
        public let id = UUID()
        public let number: Int
        public let thought: String
        public let action: String?
        public let actionResult: String?
        public let isComplete: Bool
    }
    public private(set) var steps: [ReasoningStep] = []
    public var onStepUpdate: ((ReasoningStep) -> Void)?
    public var onComplete: ((String) -> Void)?
    private let orchestrator = AgentOrchestrator.shared
    private init() {}
    public func reason(about question: String, llmGenerate: @escaping (String) async -> String) async -> String {
        steps.removeAll()
        let analysisPrompt = """
        Eres el motor de razonamiento de MACRON. Analiza la pregunta y descomponla en pasos.
        Responde UNICAMENTE con JSON: {"steps": [{"thought": "...", "needs_tool": true/false, "tool_name": "nombre o null", "tool_args": {"param": "valor"}}]}
        Pregunta: \(question)
        """
        let raw = await llmGenerate(analysisPrompt)
        guard let plan = parsePlan(from: raw) else {
            return "❌ No pude analizar. Respondo directamente: \(await llmGenerate(question))"
        }
        var ctx = "Pregunta original: \(question)\n", answer = ""
        for (i, sp) in plan.enumerated() {
            let n = i + 1
            let ts = ReasoningStep(number: n, thought: sp.thought, action: sp.needsTool ? sp.toolName : nil, actionResult: nil, isComplete: false)
            DispatchQueue.main.async { [weak self] in self?.steps.append(ts); self?.onStepUpdate?(ts) }
            ctx += "\nPaso \(n): \(sp.thought)"
            if sp.needsTool, let tn = sp.toolName {
                let res = orchestrator.execute(toolName: tn, arguments: sp.toolArgs)
                ctx += "\nResultado: \(res)"
                let cs = ReasoningStep(number: n, thought: sp.thought, action: tn, actionResult: res, isComplete: true)
                DispatchQueue.main.async { [weak self] in self?.steps[n-1] = cs; self?.onStepUpdate?(cs) }
            }
        }
        answer = await llmGenerate("Basandote en este razonamiento, responde al usuario en espanol:\n\(ctx)")
        DispatchQueue.main.async { [weak self] in self?.onComplete?(answer) }
        return answer
    }
    private struct StepPlan { let thought: String, needsTool: Bool, toolName: String?, toolArgs: [String: String] }
    private func parsePlan(from raw: String) -> [StepPlan]? {
        let c = raw.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let d = c.data(using: .utf8), let dict = try? JSONSerialization.jsonObject(with: d) as? [String: Any], let arr = dict["steps"] as? [[String: Any]] else { return nil }
        return arr.compactMap {
            guard let t = $0["thought"] as? String else { return nil }
            return StepPlan(thought: t, needsTool: $0["needs_tool"] as? Bool ?? false, toolName: $0["tool_name"] as? String, toolArgs: $0["tool_args"] as? [String: String] ?? [:])
        }
    }
}
