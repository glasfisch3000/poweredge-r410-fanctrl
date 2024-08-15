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

public struct ShellCommandResult {
    public var stdout: Data?
    public var stderr: Data?
    public var code: Int32
    public var terminationReason: Process.TerminationReason
    
    public func stdoutString(_ encoding: String.Encoding) -> String? {
        if let stdout = stdout {
            String(data: stdout, encoding: encoding)
        } else { nil }
    }
    
    public func stdoutString() throws -> String? {
        guard let stdout = stdout else { return nil }
        
        if let string = String(data: stdout, encoding: .utf8) { return string }
        if let string = String(data: stdout, encoding: .ascii) { return string }
        if let string = String(data: stdout, encoding: .utf16LittleEndian) { return string }
        if let string = String(data: stdout, encoding: .utf16BigEndian) { return string }
        if let string = String(data: stdout, encoding: .nonLossyASCII) { return string }
        
        throw ShellError.unableToReadStdout
    }
    
    public func stderrString(_ encoding: String.Encoding) -> String? {
        if let stderr = stderr {
            String(data: stderr, encoding: encoding)
        } else { nil }
    }
    
    public func stderrString() throws -> String? {
        guard let stderr = stderr else { return nil }
        
        if let string = String(data: stderr, encoding: .utf8) { return string }
        if let string = String(data: stderr, encoding: .ascii) { return string }
        if let string = String(data: stderr, encoding: .utf16LittleEndian) { return string }
        if let string = String(data: stderr, encoding: .utf16BigEndian) { return string }
        if let string = String(data: stderr, encoding: .nonLossyASCII) { return string }
        
        throw ShellError.unableToReadStderr
    }
    
    public func validate() -> Result<ShellCommandResult, ShellCommandFailure> {
        if self.code == 0 && self.terminationReason == .exit {
            return .success(self)
        } else {
            let stdout = try? self.stdoutString()
            let stderr = try? self.stderrString()
            let uncaughtSignal = self.terminationReason == .uncaughtSignal
            return .failure(ShellCommandFailure(stdout: stdout, stderr: stderr, exitCode: self.code, uncaughtSignal: uncaughtSignal))
        }
    }
}

public enum ShellError: Error, CustomStringConvertible {
    case missingStdout
    case missingStderr
    case unableToReadStdout
    case unableToReadStderr
    
    public var description: String {
        switch self {
        case .missingStdout: "shell command failed: missing stdout"
        case .missingStderr: "shell command failed: missing stderr"
        case .unableToReadStdout: "shell command failed: unable to read stdout"
        case .unableToReadStderr: "shell command failed: unable to read stderr"
        }
    }
}

public struct ShellCommandFailure: Error, CustomStringConvertible {
    public var stdout: String?
    public var stderr: String?
    public var exitCode: Int32
    public var uncaughtSignal: Bool
    
    public var description: String { "shell command failed with exit code \(exitCode)" + (uncaughtSignal ? " (uncaught signal)" : "") }
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
