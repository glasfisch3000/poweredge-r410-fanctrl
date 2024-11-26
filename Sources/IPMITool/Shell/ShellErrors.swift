public enum ShellError: Error, Sendable, CustomStringConvertible {
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

public struct ShellCommandFailure: Error, Sendable, CustomStringConvertible {
    public var stdout: String?
    public var stderr: String?
    public var exitCode: Int32
    public var uncaughtSignal: Bool
    
    public var description: String { "shell command failed with exit code \(exitCode)" + (uncaughtSignal ? " (uncaught signal)" : "") }
}
