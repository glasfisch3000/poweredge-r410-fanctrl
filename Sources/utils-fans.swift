import NIOCore

public func fans_setManualMode(_ enabled: Bool, on eventLoop: EventLoop) async throws {
    let args = ["0x30", "0x30", "0x01", enabled ? "0x00" : "0x01"]
    
    _ = try await ipmitool_executeCommand(subcmd: "raw", args: args, on: eventLoop)
        .result.get()
        .validate().get()
}

public func fans_setValue(_ value: UInt8, on eventLoop: EventLoop) async throws {
    let args = ["0x30", "0x30", "0x02", "0xff", "0x\(String(value, radix: 16))"]
    
    _ = try await ipmitool_executeCommand(subcmd: "raw", args: args, on: eventLoop)
        .result.get()
        .validate().get()
}
