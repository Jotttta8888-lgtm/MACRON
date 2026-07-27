import XCTest
@testable import MACRON

final class MACRONTests: XCTestCase {
    
    // MARK: - Hotkey Tests
    func testHotkeyServiceExists() {
        XCTAssertNotNil(HotkeyService.shared)
    }
    
    // MARK: - MenuBar Tests
    func testMenuBarServiceExists() {
        XCTAssertNotNil(MenuBarService.shared)
    }
    
    // MARK: - Clipboard Tests
    func testClipboardHistoryServiceExists() {
        XCTAssertNotNil(ClipboardHistoryService.shared)
    }
    
    func testClipboardItemCreation() {
        let item = ClipboardHistoryService.ClipboardItem(text: "Test", timestamp: Date())
        XCTAssertEqual(item.text, "Test")
    }
    
    // MARK: - Focus Mode Tests
    func testFocusModeServiceExists() {
        XCTAssertNotNil(FocusModeService.shared)
    }
    
    // MARK: - Plugin System Tests
    func testPluginSystemExists() {
        XCTAssertNotNil(PluginSystem.shared)
    }
    
    // MARK: - System Monitor Tests
    func testSystemMonitorExists() {
        XCTAssertNotNil(SystemMonitorService.shared)
    }
    
    // MARK: - Meeting Assistant Tests
    func testMeetingAssistantExists() {
        XCTAssertNotNil(MeetingAssistantService.shared)
    }
    
    // MARK: - AI Vision Tests
    func testAIVisionServiceExists() {
        XCTAssertNotNil(AIVisionService.shared)
    }
    
    // MARK: - File Organizer Tests
    func testFileOrganizerExists() {
        XCTAssertNotNil(SmartFileOrganizer.shared)
    }
    
    // MARK: - Smart Reminders Tests
    func testSmartRemindersExists() {
        XCTAssertNotNil(SmartRemindersService.shared)
    }
    
    // MARK: - Performance Tests
    func testAppLaunchPerformance() {
        measure {
            _ = NSApplication.shared
        }
    }
}
