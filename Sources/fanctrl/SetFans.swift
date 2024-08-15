import NIOPosix
import ArgumentParser
import IPMITool

public struct SetFans: AsyncParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "setfans",
        abstract: "Set the overall fan usage",
        version: "1.0.0",
        shouldDisplay: true,
        subcommands: [],
        groupedSubcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong,
        aliases: ["set"]
    )
    
    public init() { }
    
    @Argument(help: .init("The fan setting (auto|off|full|<number>). Specify <number> as decimal (0-1.0) or percentage (0-100%).", visibility: .default), completion: .list(["auto", "full", "off"])) public var fanMode: FanMode
    
    public mutating func run() async throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let eventLoop = eventLoopGroup.next()
        
        do {
            switch fanMode {
            case .manual(let percentage):
                try await fans_setManualMode(true, on: eventLoop)
                try await fans_setValue(percentage, on: eventLoop)
            case .automatic:
                try await fans_setManualMode(false, on: eventLoop)
            }
        } catch let error as ShellCommandFailure {
            if let stderr = error.stderr {
                print(stderr, to: &standardError)
            }
            throw error
        }
    }
}

public enum FanMode: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "auto", "automatic": self = .automatic
        case "off": self = .manual(percentage: 0)
        case "full": self = .manual(percentage: 100)
        default:
            guard let match = argument.wholeMatch(of: /(?<percentage>[0-9]+)%|(?<float>[0-9]*\.[0-9]+)/) else {
                return nil
            }
            
            if let percentage = match.output.percentage {
                guard let parsed = UInt8(percentage) else {
                    return nil
                }
                
                self = switch parsed {
                case 0...100: .manual(percentage: parsed)
                default: .manual(percentage: 100)
                }
            } else if let float = match.output.float {
                guard let parsed = Double(float) else {
                    return nil
                }
                
                switch parsed {
                case 0...1: self = .manual(percentage: UInt8((parsed * 100).rounded()))
                case ..<0: self = .manual(percentage: 0)
                case 1...: self = .manual(percentage: 100)
                default: return nil
                }
            } else {
                return nil
            }
        }
    }
    
    case manual(percentage: UInt8)
    case automatic
    
    public static let full = FanMode.manual(percentage: 100)
    public static let off = FanMode.manual(percentage: 0)
}
