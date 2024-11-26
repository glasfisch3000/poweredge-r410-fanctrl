public enum Sensor: UInt8, Sendable, Hashable, CaseIterable {
    case ambientTemperature = 0x0E
    case planarTemperature = 0x0F
}

extension Sensor: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ambientTemperature: "Ambient Temperature"
        case .planarTemperature: "Planar Temperature"
        }
    }
}

extension Sensor: Comparable {
    public static func < (lhs: Sensor, rhs: Sensor) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
