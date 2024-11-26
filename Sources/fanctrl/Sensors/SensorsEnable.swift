import NIOPosix
import ArgumentParser
import IPMITool

public struct SensorsEnable: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "enable",
        abstract: "Enable value scanning from one or more sensors.",
        version: "0.0.0",
        shouldDisplay: true,
        subcommands: [],
        groupedSubcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong,
        aliases: []
    )
    
    public init() { }
    
    @Option(name: .customLong("sensors"), completion: .none)
    public var sensors: [Sensor] = []
    
    @Flag(name: .customLong("all"))
    public var enableAllSensors: Bool = false
    
    public func run() async throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        defer {
            eventLoopGroup.shutdownGracefully { error in
                // if an error occurs, print it
                error.flatMap { print($0, to: &standardError) }
            }
        }
        
        let sensors = self.enableAllSensors ? Sensor.allCases : self.sensors
        if sensors.isEmpty {
            throw EnableError.noSensorsSpecified
        }
        
        let tasks = sensors.sorted().map { sensor in
            let task = Task {
                var state = try await sensor.read(on: eventLoopGroup.next()).state
                state.valueScanningEnabled = true
                try await sensor.setState(state, on: eventLoopGroup.next())
            }
            return (sensor, task)
        }
        
        for (sensor, task) in tasks {
            print("0x\(String(format: "%02X", sensor.rawValue)) (\(sensor.description)):", terminator: " ")
            
            do {
                _ = try await task.value
                print("enabled")
            } catch let error as SensorReadError {
                switch error {
                case .invalidIPMIResponse: print("invalid IPMI response")
                case .sensorIsInaccessible: print("sensor is inaccessible or missing")
                }
            } catch let error as ShellError {
                switch error {
                case .missingStdout, .missingStderr: print("missing IPMI response")
                case .unableToReadStdout, .unableToReadStderr: print("unable to read IPMI response")
                }
            } catch let error as ShellCommandFailure {
                if let stderr = error.stderr {
                    print(stderr)
                } else if error.uncaughtSignal {
                    print("ipmitool exited with uncaught signal")
                } else {
                    print("ipmitool exited with code \(error.exitCode)")
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension SensorsEnable {
    enum EnableError: Error, CustomStringConvertible {
        case noSensorsSpecified
        
        var description: String {
            switch self {
            case .noSensorsSpecified: "No sensors were specified."
            }
        }
    }
}
