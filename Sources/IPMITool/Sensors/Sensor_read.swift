import NIOCore

public enum SensorReadError: Error, Hashable, Sendable, Codable, CustomStringConvertible {
    case invalidIPMIResponse
    case sensorIsInaccessible
    
    public var description: String {
        switch self {
        case .invalidIPMIResponse: "sensor read command failed: invalid IPMI response"
        case .sensorIsInaccessible: "sensor read command failed: sensor is inaccessible or missing"
        }
    }
}

extension Sensor {
    public func read(on eventLoop: EventLoop) async throws -> SensorReading {
        // ipmitool arguments: 2x command code for read sensor + sensor ID
        let args = ["0x04", "0x2d", "0x\(String(self.rawValue, radix: 16))"]
        
        guard let result = try await ipmitool_executeCommand(subcmd: "raw", args: args, on: eventLoop)
            .result.get()
            .validate()
            .stdoutString() else {
            throw ShellError.missingStdout
        }
        
        // try to parse ipmitool response
        guard let match = result.wholeMatch(of: /\s*(?<reading>[A-Fa-f0-9]{2})\s+(?<state>[A-Fa-f0-9]{2})(\s+(?<thresholds>[A-Fa-f0-9]{2})(\s+[A-Fa-f0-9]{2})?)?\s*/),
              let readingRaw = UInt8(match.output.reading, radix: 16),
              let stateRaw = UInt8(match.output.state, radix: 16) else {
            throw SensorReadError.invalidIPMIResponse
        }
        
        // check for invalidity bit
        // if this bit is set, sensor reading and state are invalid
        guard stateRaw & 0b0010_0000 == 0 else {
            throw SensorReadError.sensorIsInaccessible
        }
        
        // parse sensor state from state bits
        let state = SensorState(eventMessages: stateRaw & 0b1000_0000 != 0,
                                valueScanning: stateRaw & 0b0100_0000 != 0)
        
        // if value scanning is enabled, get reading value
        let reading = state.valueScanningEnabled ? readingRaw : nil
        
        return SensorReading(state: state, reading: reading)
    }
}
