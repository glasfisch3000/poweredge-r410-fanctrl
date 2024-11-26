public struct SensorReading: Hashable, Sendable, Codable {
    public var state: SensorState
    public var reading: UInt8?
}

extension SensorReading {
    public func temperatureReading() -> Int8? {
        // map the raw reading (0..255) to the actual result (-128..127)
        if let reading = reading {
            if reading < 128 { -128 + Int8(reading) }
            else { Int8(reading - 128) }
        } else { nil }
    }
}
