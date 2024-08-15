import NIOCore

public struct SensorReading: Hashable, Codable {
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

public struct SensorState: Hashable, Codable {
    public var eventMessagesEnabled: Bool
    public var valueScanningEnabled: Bool
    
    public init(parsing raw: UInt8) throws {
        guard raw & 0b0010_0000 == 0 else { // if this bit is set, sensor reading and state are invalid
            throw SensorReadError.sensorIsInaccessible
        }
        
        self.eventMessagesEnabled = raw & 0b1000_0000 != 0 // if this bit is set, event messages are enabled
        self.valueScanningEnabled = raw & 0b0100_0000 != 0 // if this bit is set, sensor reading is enabled
    }
}

public enum SensorReadError: Error, Hashable, Codable, CustomStringConvertible {
    case invalidIPMIResponse
    case sensorIsInaccessible
    
    public var description: String {
        switch self {
        case .invalidIPMIResponse: "sensor read command failed: invalid IPMI response"
        case .sensorIsInaccessible: "sensor read command failed: sensor is inaccessible or missing"
        }
    }
}

public func sensor_read(_ sensorID: UInt8, on eventLoop: EventLoop) async throws -> SensorReading {
    let args = ["0x04", "0x2d", "0x\(String(sensorID, radix: 16))"]
    
    guard let result = try await ipmitool_executeCommand(subcmd: "raw", args: args, on: eventLoop)
        .result.get()
        .validate().get()
        .stdoutString() else {
        throw ShellError.missingStdout
    }
    
    guard let match = result.wholeMatch(of: /\s*(?<reading>[A-Fa-f0-9]{2}) (?<state>[A-Fa-f0-9]{2}) (?<thresholds>[A-Fa-f0-9]{2})? [A-Fa-f0-9]{2}?\s*/),
          let readingRaw = UInt8(match.output.reading, radix: 16),
          let stateRaw = UInt8(match.output.state, radix: 16) else {
        throw SensorReadError.invalidIPMIResponse
    }
    
    let state = try SensorState(parsing: stateRaw) // fails if the invalidity bit is set, meaning the sensor is inaccessible or missing
    let reading = state.valueScanningEnabled ? readingRaw : nil
    
    return SensorReading(state: state, reading: reading)
}
