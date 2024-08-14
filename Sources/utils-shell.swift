import Foundation
import NIOCore

internal struct ShellCommand {
    private var task: Process
    
    init(task: Process, result: EventLoopFuture<ShellCommandResult>) {
        self.task = task
        self.result = result
    }
    
    var result: EventLoopFuture<ShellCommandResult>
    
    var processID: Int32 { task.processIdentifier }
    var isRunning: Bool { task.isRunning }
}

internal struct ShellCommandResult {
    var stdout: Data?
    var stderr: Data?
    var code: Int32
    var terminationReason: Process.TerminationReason
    
    func stdoutString(_ encoding: String.Encoding) -> String? {
        if let stdout = stdout {
            String(data: stdout, encoding: encoding)
        } else { nil }
    }
    
    func stdoutString() throws -> String? {
        guard let stdout = stdout else { return nil }
        
        if let string = String(data: stdout, encoding: .utf8) { return string }
        if let string = String(data: stdout, encoding: .ascii) { return string }
        if let string = String(data: stdout, encoding: .utf16LittleEndian) { return string }
        if let string = String(data: stdout, encoding: .utf16BigEndian) { return string }
        if let string = String(data: stdout, encoding: .nonLossyASCII) { return string }
        
        throw ShellError.unableToReadStdout
    }
    
    func stderrString(_ encoding: String.Encoding) -> String? {
        if let stderr = stderr {
            String(data: stderr, encoding: encoding)
        } else { nil }
    }
    
    func stderrString() throws -> String? {
        guard let stderr = stderr else { return nil }
        
        if let string = String(data: stderr, encoding: .utf8) { return string }
        if let string = String(data: stderr, encoding: .ascii) { return string }
        if let string = String(data: stderr, encoding: .utf16LittleEndian) { return string }
        if let string = String(data: stderr, encoding: .utf16BigEndian) { return string }
        if let string = String(data: stderr, encoding: .nonLossyASCII) { return string }
        
        throw ShellError.unableToReadStderr
    }
    
    func validate() -> Result<ShellCommandResult, ShellCommandFailure> {
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

internal enum ShellError: Error, CustomStringConvertible {
    case missingStdout
    case missingStderr
    case unableToReadStdout
    case unableToReadStderr
    
    var description: String {
        switch self {
        case .missingStdout: "shell command failed: missing stdout"
        case .missingStderr: "shell command failed: missing stderr"
        case .unableToReadStdout: "shell command failed: unable to read stdout"
        case .unableToReadStderr: "shell command failed: unable to read stderr"
        }
    }
}

internal struct ShellCommandFailure: Error, CustomStringConvertible {
    var stdout: String?
    var stderr: String?
    var exitCode: Int32
    var uncaughtSignal: Bool
    
    var description: String { "shell command failed with exit code \(exitCode)" + (uncaughtSignal ? " (uncaught signal)" : "") }
}

internal func shell(cmd: String, args: [String] = [], sudo: Bool = false, on eventLoop: EventLoop) throws -> ShellCommand {
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

internal func ipmitool_executeCommand(subcmd: String, args: [String], on eventLoop: EventLoop) throws -> ShellCommand {
    try shell(cmd: "/usr/local/bin/ipmitool", args: [subcmd] + args, sudo: true, on: eventLoop)
}
