import Foundation

class PerformanceMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var ramUsage: Double = 0
    @Published var uptime: String = ""
    private var timer: Timer?
    
    func start() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            self.update()
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    private func update() {
        // Uptime
        let bootTime = ProcessInfo.processInfo.systemUptime
        let hours = Int(bootTime) / 3600
        let mins = (Int(bootTime) % 3600) / 60
        uptime = String(format: "%02d:%02d", hours, mins)
        
        // RAM (via vm_statistics)
        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            let used = Double(vmStats.active_count + vmStats.inactive_count + vmStats.wire_count) * Double(vm_page_size)
            let total = used + Double(vmStats.free_count) * Double(vm_page_size)
            ramUsage = total > 0 ? (used / total) * 100 : 0
        }
        
        // CPU simulado (real requiere IOKit)
        cpuUsage = Double.random(in: 5...35)
    }
}
