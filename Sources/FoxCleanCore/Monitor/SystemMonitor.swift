import Darwin
import Foundation
import IOKit
import IOKit.ps

public struct ProcessSnapshot: Codable, Hashable, Identifiable, Sendable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let name: String
    public let path: String
    public let residentMemoryBytes: UInt64
    public let cpuTimeSeconds: Double
}

public struct SystemSnapshot: Codable, Sendable {
    public let timestamp: Date
    public let cpuLoad: Double
    public let memoryUsedRatio: Double
    public let memoryUsedBytes: UInt64
    public let memoryTotalBytes: UInt64
    public let diskFreeBytes: Int64
    public let diskTotalBytes: Int64
    public let diskReadBytesPerSecond: Double
    public let diskWrittenBytesPerSecond: Double
    public let networkReceivedBytesPerSecond: Double
    public let networkSentBytesPerSecond: Double
    public let processCount: Int
    public let topProcesses: [ProcessSnapshot]
    public let batteryPercent: Double?
    public let thermalState: String
    public let healthScore: Int
}

public actor SystemMonitor {
    private var previousCPU: CPUCounters?
    private var previousDiskIO: DiskIOCounters?
    private var previousDiskIODate: Date?
    private var previousNetwork: NetworkCounters?
    private var previousNetworkDate: Date?

    public init() {}

    public func snapshot() -> SystemSnapshot {
        let now = Date()
        let cpu = cpuLoad()
        let memory = memoryInfo()
        let disk = diskInfo()
        let diskIO = diskIOCounters()
        let diskIOInterval = previousDiskIODate.map { max(0.001, now.timeIntervalSince($0)) } ?? 1
        let previousDiskIO = previousDiskIO
        self.previousDiskIO = diskIO
        previousDiskIODate = now
        let network = networkCounters()
        let interval = previousNetworkDate.map { max(0.001, now.timeIntervalSince($0)) } ?? 1
        let previousNetwork = previousNetwork
        self.previousNetwork = network
        previousNetworkDate = now
        let battery = batteryPercent()
        let thermalState = ProcessInfo.processInfo.thermalState
        let processes = topProcesses(limit: 5)
        let score = HealthScore.calculate(cpuLoad: cpu, memoryUsedRatio: memory.ratio, freeRatio: disk.total > 0 ? Double(disk.free) / Double(disk.total) : 0.0, batteryPercent: battery, thermalState: thermalState)
        return SystemSnapshot(
            timestamp: now,
            cpuLoad: cpu,
            memoryUsedRatio: memory.ratio,
            memoryUsedBytes: memory.used,
            memoryTotalBytes: memory.total,
            diskFreeBytes: disk.free,
            diskTotalBytes: disk.total,
            diskReadBytesPerSecond: previousDiskIO.map { Double(diskIO.readBytes.saturatingSubtract($0.readBytes)) / diskIOInterval } ?? 0,
            diskWrittenBytesPerSecond: previousDiskIO.map { Double(diskIO.writtenBytes.saturatingSubtract($0.writtenBytes)) / diskIOInterval } ?? 0,
            networkReceivedBytesPerSecond: previousNetwork.map { Double(network.receivedBytes.saturatingSubtract($0.receivedBytes)) / interval } ?? 0,
            networkSentBytesPerSecond: previousNetwork.map { Double(network.sentBytes.saturatingSubtract($0.sentBytes)) / interval } ?? 0,
            processCount: processCount(),
            topProcesses: processes,
            batteryPercent: battery,
            thermalState: thermalState.label,
            healthScore: score
        )
    }

    public func stream(interval: Duration = .seconds(1)) -> AsyncStream<SystemSnapshot> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    continuation.yield(snapshot())
                    try? await Task.sleep(for: interval)
                }
                continuation.finish()
            }
        }
    }

    private func diskInfo() -> (free: Int64, total: Int64) {
        let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/")
        return (attrs?[.systemFreeSize] as? Int64 ?? 0, attrs?[.systemSize] as? Int64 ?? 0)
    }

    private func diskIOCounters() -> DiskIOCounters {
        guard let matching = IOServiceMatching("IOBlockStorageDriver") else {
            return DiskIOCounters(readBytes: 0, writtenBytes: 0)
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return DiskIOCounters(readBytes: 0, writtenBytes: 0)
        }
        defer { IOObjectRelease(iterator) }

        var readBytes: UInt64 = 0
        var writtenBytes: UInt64 = 0

        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }
            defer { IOObjectRelease(service) }

            guard let stats = IORegistryEntryCreateCFProperty(service, "Statistics" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? [String: Any]
            else { continue }

            readBytes += uint64Value(stats["Bytes (Read)"])
            writtenBytes += uint64Value(stats["Bytes (Write)"])
        }

        return DiskIOCounters(readBytes: readBytes, writtenBytes: writtenBytes)
    }

    private func cpuLoad() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        let counters = CPUCounters(
            user: UInt64(info.cpu_ticks.0),
            system: UInt64(info.cpu_ticks.1),
            idle: UInt64(info.cpu_ticks.2),
            nice: UInt64(info.cpu_ticks.3)
        )
        defer { previousCPU = counters }

        guard let previousCPU else {
            return counters.load
        }
        let delta = counters - previousCPU
        return delta.load
    }

    private func memoryInfo() -> (ratio: Double, used: UInt64, total: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory
        guard total > 0 else { return (0, 0, 0) }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0, total) }

        let usedPages = UInt64(stats.active_count + stats.inactive_count + stats.wire_count + stats.compressor_page_count)
        let used = usedPages * UInt64(pageSize)
        let ratio = min(1, max(0, Double(used) / Double(total)))
        return (ratio, used, total)
    }

    private func networkCounters() -> NetworkCounters {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0, let addresses else {
            return NetworkCounters(receivedBytes: 0, sentBytes: 0)
        }
        defer { freeifaddrs(addresses) }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        var pointer: UnsafeMutablePointer<ifaddrs>? = addresses
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            let flags = Int32(current.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }
            guard let data = current.pointee.ifa_data?.assumingMemoryBound(to: if_data.self).pointee else { continue }
            received += UInt64(data.ifi_ibytes)
            sent += UInt64(data.ifi_obytes)
        }
        return NetworkCounters(receivedBytes: received, sentBytes: sent)
    }

    private func processCount() -> Int {
        let bytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytes > 0 else { return 0 }
        return Int(bytes) / MemoryLayout<pid_t>.stride
    }

    private func topProcesses(limit: Int) -> [ProcessSnapshot] {
        let bytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytes > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(bytes) / MemoryLayout<pid_t>.stride)
        let readBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, bytes)
        guard readBytes > 0 else { return [] }

        return pids.compactMap { pid -> ProcessSnapshot? in
            guard pid > 0 else { return nil }
            var taskInfo = proc_taskinfo()
            let taskInfoSize = MemoryLayout<proc_taskinfo>.stride
            let read = withUnsafeMutablePointer(to: &taskInfo) { pointer in
                pointer.withMemoryRebound(to: UInt8.self, capacity: taskInfoSize) { rebound in
                    proc_pidinfo(pid, PROC_PIDTASKINFO, 0, rebound, Int32(taskInfoSize))
                }
            }
            guard read == Int32(taskInfoSize) else { return nil }

            var pathBuffer = [CChar](repeating: 0, count: 4096)
            let pathLength = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
            let path = pathLength > 0 ? String(cString: pathBuffer) : ""
            let name = path.isEmpty ? "pid \(pid)" : URL(fileURLWithPath: path).lastPathComponent
            let cpuTime = Double(taskInfo.pti_total_user + taskInfo.pti_total_system) / 1_000_000_000
            return ProcessSnapshot(
                pid: pid,
                name: name,
                path: path,
                residentMemoryBytes: UInt64(taskInfo.pti_resident_size),
                cpuTimeSeconds: cpuTime
            )
        }
        .sorted {
            if $0.cpuTimeSeconds == $1.cpuTimeSeconds {
                return $0.residentMemoryBytes > $1.residentMemoryBytes
            }
            return $0.cpuTimeSeconds > $1.cpuTimeSeconds
        }
        .prefix(limit)
        .map { $0 }
    }

    private func batteryPercent() -> Double? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  let current = description[kIOPSCurrentCapacityKey] as? Double,
                  let maxCapacity = description[kIOPSMaxCapacityKey] as? Double,
                  maxCapacity > 0
            else { continue }
            return Swift.min(1, Swift.max(0, current / maxCapacity))
        }
        return nil
    }

    private func uint64Value(_ value: Any?) -> UInt64 {
        if let value = value as? UInt64 { return value }
        if let value = value as? Int64 { return value > 0 ? UInt64(value) : 0 }
        if let value = value as? Int { return value > 0 ? UInt64(value) : 0 }
        if let value = value as? NSNumber { return value.uint64Value }
        return 0
    }
}

private struct CPUCounters: Sendable {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64

    var total: UInt64 { user + system + idle + nice }
    var active: UInt64 { user + system + nice }
    var load: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(active) / Double(total)))
    }

    static func - (lhs: CPUCounters, rhs: CPUCounters) -> CPUCounters {
        CPUCounters(
            user: lhs.user.saturatingSubtract(rhs.user),
            system: lhs.system.saturatingSubtract(rhs.system),
            idle: lhs.idle.saturatingSubtract(rhs.idle),
            nice: lhs.nice.saturatingSubtract(rhs.nice)
        )
    }
}

private struct NetworkCounters: Sendable {
    let receivedBytes: UInt64
    let sentBytes: UInt64
}

private struct DiskIOCounters: Sendable {
    let readBytes: UInt64
    let writtenBytes: UInt64
}

private extension UInt64 {
    func saturatingSubtract(_ other: UInt64) -> UInt64 {
        self >= other ? self - other : 0
    }
}

public enum HealthScore {
    public static func calculate(cpuLoad: Double, memoryUsedRatio: Double, freeRatio: Double, batteryPercent: Double?, thermalState: ProcessInfo.ThermalState = .nominal) -> Int {
        var score = 100.0
        score -= min(35, cpuLoad * 35)
        score -= min(30, memoryUsedRatio * 30)
        score -= freeRatio < 0.1 ? 25 : (freeRatio < 0.2 ? 10 : 0)
        if let batteryPercent, batteryPercent < 0.15 { score -= 10 }
        switch thermalState {
        case .nominal:
            break
        case .fair:
            score -= 5
        case .serious:
            score -= 15
        case .critical:
            score -= 25
        @unknown default:
            score -= 5
        }
        return max(0, min(100, Int(score.rounded())))
    }
}

private extension ProcessInfo.ThermalState {
    var label: String {
        switch self {
        case .nominal:
            return "nominal"
        case .fair:
            return "fair"
        case .serious:
            return "serious"
        case .critical:
            return "critical"
        @unknown default:
            return "unknown"
        }
    }
}
