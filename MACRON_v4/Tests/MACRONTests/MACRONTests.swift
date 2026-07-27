import XCTest
@testable import MACRON
final class MACRONTests: XCTestCase {
    func testBiometricAvailability() {
        let s = BiometricAuthService.shared
        XCTAssertNotNil(s.isAvailable)
    }
    func testWindowManagerSingleton() {
        XCTAssertTrue(WindowManager.shared === WindowManager.shared)
    }
    func testThemeToggle() {
        let tm = ThemeManager()
        let i = tm.isDarkMode
        tm.toggleTheme()
        XCTAssertNotEqual(tm.isDarkMode, i)
    }
}
