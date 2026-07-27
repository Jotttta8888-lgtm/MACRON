import Foundation
import IOBluetooth

class BluetoothManagerService: ObservableObject {
    static let shared = BluetoothManagerService()
    @Published var pairedDevices: [String] = []
    
    func listDevices() -> [String] {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return [] }
        pairedDevices = devices.compactMap { $0.name }
        return pairedDevices
    }
    
    func connectDevice(named: String) {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return }
        for device in devices where device.name?.contains(named) == true {
            device.openConnection()
            NotificationService.shared.send(title: "MACRON Bluetooth", body: "Conectando: " + (device.name ?? "dispositivo"))
        }
    }
    
    func disconnectDevice(named: String) {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return }
        for device in devices where device.name?.contains(named) == true {
            device.closeConnection()
            NotificationService.shared.send(title: "MACRON Bluetooth", body: "Desconectando: " + (device.name ?? "dispositivo"))
        }
    }
}
