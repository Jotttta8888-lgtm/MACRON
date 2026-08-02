import Foundation

public enum VersionManager {
    public static var displayVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?.?.?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(short) · \(build) features"
    }
    public static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?.?.?"
    }
    public static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
    public static var fullVersion: String {
        let short = shortVersion
        let build = buildNumber
        return "\(short) (\(build) features))"
    }
}
