import NIOPosix
import ArgumentParser
import IPMITool

public struct GetTemperature: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "gettemp",
        abstract: "Get readings from temperature sensors.",
        version: "0.0.0",
        shouldDisplay: true,
        subcommands: [],
        groupedSubcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong,
        aliases: []
    )
    
    public static let defaultSensors: [Sensor] = [.ambientTemperature, .planarTemperature]
    
    public init() { }
    
    @Option(name: .customLong("sensors"), completion: .none)
    public var sensors: [Sensor] = []
    
    public mutating func run() async throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        defer {
            eventLoopGroup.shutdownGracefully { error in
                // if an error occurs, print it
                error.flatMap { print($0, to: &standardError) }
            }
        }
        
        let sensors = self.sensors.isEmpty ? Self.defaultSensors : self.sensors
        
        let tasks = sensors.sorted().map { sensor in
            let task = Task {
                try await sensor.read(on: eventLoopGroup.next())
            }
            return (sensor, task)
        }
        
        for (sensor, task) in tasks {
            print("0x\(String(format: "%02X", sensor.rawValue)) (\(sensor.description)):", terminator: " ")
            
            do {
                if let temp = try await task.value.temperatureReading() {
                    print("\(temp)°C")
                } else {
                    print("sensor is disabled")
                }
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


