import LocalAuthentication

class BiometricAuthService {
    static let shared = BiometricAuthService()
    private let context = LAContext()
    
    var isAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var biometryType: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometria"
        }
    }
    
    func authenticate(reason: String = "Desbloquear MACRON", completion: @escaping (Bool, String?) -> Void) {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error?.localizedDescription ?? "Biometria no disponible")
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error?.localizedDescription)
            }
        }
    }
}
