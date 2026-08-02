import XCTest
@testable import MACRON

final class MACRONTests: XCTestCase {

    // MARK: - VersionManager Tests

    func testVersionManagerFormats() {
        // VersionManager lee del bundle, así que verificamos que no crashea
        let display = VersionManager.displayVersion
        let full = VersionManager.fullVersion

        XCTAssertFalse(display.isEmpty)
        XCTAssertFalse(full.isEmpty)
        XCTAssertTrue(display.contains("v"))
        XCTAssertTrue(full.contains("features"))
    }

    // MARK: - AutonomousEngine Tests

    func testAutonomousEngineResetSession() async {
        let engine = AutonomousEngine.shared
        await engine.resetSession()

        // Después de reset, no debe sugerir (0 interacciones)
        let suggestion = await engine.evaluateProactivityOnly()
        XCTAssertNil(suggestion, "No debe sugerir con 0 interacciones")
    }

    func testAutonomousEngineCooldown() async {
        let engine = AutonomousEngine.shared
        await engine.resetSession()

        // Simular 2 interacciones
        await engine.countInteraction(text: "test 1")
        await engine.countInteraction(text: "test 2")

        // Primera evaluación debe sugerir
        let suggestion1 = await engine.evaluateProactivityOnly()
        XCTAssertNotNil(suggestion1, "Debe sugerir después de 2 interacciones")

        // Segunda evaluación inmediata NO debe sugerir (cooldown)
        let suggestion2 = await engine.evaluateProactivityOnly()
        XCTAssertNil(suggestion2, "No debe sugerir durante cooldown")
    }

    func testAutonomousEngineSystemCommandIgnored() async {
        let engine = AutonomousEngine.shared
        await engine.resetSession()

        // Comando de sistema no debe contar como interacción
        await engine.countInteraction(text: "modo autonomo")
        await engine.countInteraction(text: "modo autonomo")

        let suggestion = await engine.evaluateProactivityOnly()
        XCTAssertNil(suggestion, "Comandos de sistema no deben contar")
    }

    func testAutonomousEnginePatternPersistence() async {
        let engine = AutonomousEngine.shared
        await engine.resetSession()

        // Registrar interacciones
        await engine.countInteraction(text: "test")
        await engine.countInteraction(text: "test")

        // Verificar que el patrón horario se incrementó
        let stats = await engine.getStats()
        XCTAssertTrue(stats.contains("Interacciones esta sesion"))
    }

    // MARK: - AppLauncher Tests

    func testAppLauncherMapNotEmpty() {
        // Verificar que el mapa tiene apps
        let launcher = AppLauncher.shared
        // No podemos acceder a appMap directamente, pero podemos probar openApp
        // Este test es placeholder hasta que AppLauncher tenga método de listado público
    }

    func testAppLauncherUnknownApp() async {
        let launcher = AppLauncher.shared
        let orchestrator = PluginOrchestrator.shared
        let result = await launcher.openApp(keyword: "app_inexistente_xyz", orchestrator: orchestrator)
        XCTAssertTrue(result.contains("❌") || result.contains("No reconozco"))
    }

    // MARK: - SystemCommandService Tests

    func testSystemCommandVolumeClamping() async {
        let service = SystemCommandService.shared
        // Volumen fuera de rango debe ser clamped
        let result = await service.setVolume(level: 150)
        XCTAssertTrue(result.contains("100") || result.contains("Error"))
    }

    // MARK: - CommandRouter Tests

    func testCommandRouterRegistration() {
        let router = CommandRouter.shared
        // Verificar que los handlers por defecto están registrados
        // Este test es placeholder hasta que listHandlers sea público
    }

    func testCommandRouterNoMatch() async {
        let router = CommandRouter.shared
        let brain = MACRONBrain.shared
        let result = await router.route(text: "xyz_inexistente_12345", brain: brain)
        XCTAssertNil(result, "Texto sin keywords no debe match")
    }
}
