import Foundation
import CloudKit

class iCloudSyncService: ObservableObject {
    static let shared = iCloudSyncService()
    private let kvStore = NSUbiquitousKeyValueStore.default
    private let container = CKContainer.default()
    private let database: CKDatabase
    @Published var syncStatus = "Sin sincronizar"
    
    init() {
        database = container.privateCloudDatabase
        setupSync()
    }
    
    func setupSync() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleExternalChange), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: kvStore)
        kvStore.synchronize()
    }
    
    @objc private func handleExternalChange(_ notification: Notification) {
        syncStatus = "Sincronizado con iCloud"
    }
    
    func setPreference(_ value: Any, forKey key: String) {
        kvStore.set(value, forKey: key)
        kvStore.synchronize()
    }
    
    func getPreference(forKey key: String) -> Any? {
        return kvStore.object(forKey: key)
    }
}
