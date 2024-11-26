import Foundation

public struct ShellCommandResult: Sendable {
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
    
    @discardableResult
    public func validate() throws(ShellCommandFailure) -> ShellCommandResult {
        if self.code == 0 && self.terminationReason == .exit {
            return self
        } else {
            let stdout = try? self.stdoutString()
            let stderr = try? self.stderrString()
            let uncaughtSignal = self.terminationReason == .uncaughtSignal
            throw ShellCommandFailure(stdout: stdout, stderr: stderr, exitCode: self.code, uncaughtSignal: uncaughtSignal)
        }
    }
}
