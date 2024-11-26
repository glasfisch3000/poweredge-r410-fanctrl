import Foundation
import NIOCore

public struct ShellCommand {
    private var task: Process
    
    internal init(task: Process, result: EventLoopFuture<ShellCommandResult>) {
        self.task = task
        self.result = result
    }
    
    public var result: EventLoopFuture<ShellCommandResult>
    
    public var processID: Int32 { task.processIdentifier }
    public var isRunning: Bool { task.isRunning }
}

public func shell(cmd: String, args: [String] = [], sudo: Bool = false, on eventLoop: EventLoop) throws -> ShellCommand {
    let task = Process()
    let stdout = Pipe()
    let stderr = Pipe()
    
    task.standardOutput = stdout
    task.standardError = stderr
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = (sudo ? ["/usr/bin/sudo", "--non-interactive", "--"] : []) + [cmd] + args
    task.qualityOfService = .userInitiated
    
    let promise = eventLoop.makePromise(of: ShellCommandResult.self)
    
    task.terminationHandler = { process in
        do {
            promise.succeed(ShellCommandResult(
                stdout: try stdout.fileHandleForReading.readToEnd(),
                stderr: try stderr.fileHandleForReading.readToEnd(),
                code: process.terminationStatus,
                terminationReason: process.terminationReason
            ))
        } catch {
            promise.fail(error)
        }
    }
    
    try task.run()
    
    return ShellCommand(task: task, result: promise.futureResult)
}

public func ipmitool_executeCommand(subcmd: String, args: [String], on eventLoop: EventLoop) throws -> ShellCommand {
    try shell(cmd: "/usr/local/bin/ipmitool", args: [subcmd] + args, sudo: true, on: eventLoop)
}
