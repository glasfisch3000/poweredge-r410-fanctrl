import NIOCore

extension Sensor {
    public func setState(_ state: SensorState, on eventLoop: EventLoop) async throws {
        // ipmitool arguments: 2x command code for set sensor state + sensor ID
        var args = ["0x04", "0x28", "0x\(String(self.rawValue, radix: 16))"]
        
        var stateBits: UInt8 = 0
        if state.eventMessagesEnabled { stateBits |= 0b1000_000 }
        if state.valueScanningEnabled { stateBits |= 0b0100_000 }
        
        // append state bits to ipmitool args
        args.append("0x\(String(stateBits, radix: 16))")
        
        // add event bits to ipmitool args
        // these are for individual event enables/disables
        // not covered yet, we'll just put in zeros
        args.append("0x00")
        args.append("0x00")
        args.append("0x00")
        args.append("0x00")
        
        try await ipmitool_executeCommand(subcmd: "raw", args: args, on: eventLoop)
            .result.get()
            .validate()
    }
}
