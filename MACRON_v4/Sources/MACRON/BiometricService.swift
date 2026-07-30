import Foundation
public actor BiometricService {
    public static let shared = BiometricService()
    private init() {}
    public func authenticate() -> String {
        return "🔒 Face ID / Touch ID: Usa 'Desbloquear Macron' para simular."
    }
    public func unlock() -> String {
        return "🔓 MACRON desbloqueado."
    }
}
