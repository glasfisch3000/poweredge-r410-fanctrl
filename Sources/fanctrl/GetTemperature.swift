import NIOPosix
import ArgumentParser
import IPMITool

public struct GetTemperature: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "gettemp",
        abstract: "Get readings from temperature sensors",
        version: "0.0.0",
        shouldDisplay: true,
        subcommands: [],
        groupedSubcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong,
        aliases: []
    )
    
    public static var knownSensors: [UInt8: String] = [
        0x0E: "Ambient Temperature",
        0x0F: "Planar Temperature",
    ]
    
    public init() { }
    
    @Option(name: .customLong("sensors", withSingleDash: false), completion: .none, transform: { input in
        guard let match = input.wholeMatch(of: /(0x)?(?<number>[0-9A-Fa-f]{2})/) else {
            throw ValidationError("invalid sensor ID: \"\(input)\"")
        }
        guard let sensorID = UInt8(match.output.number) else {
            throw ValidationError("invalid sensor ID: \"(input)\"")
        }
        return sensorID
    }) public var sensorIDs: [UInt8] = []
    
    public mutating func run() async throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        let eventLoop = eventLoopGroup.next()
        
        let sensors: [UInt8: String?] = if !sensorIDs.isEmpty {
            Dictionary(sensorIDs.map { ($0, Self.knownSensors[$0]) }) { $0 ?? $1 ?? nil } // sort sensor ids, assign names if known
        } else {
            Self.knownSensors
        }
        await withTaskGroup(of: (UInt8, String?, Result<Int8?, Error>).self) { group in
            for (sensorID, sensorName) in sensors {
                group.addTask {
                    do {
                        let temperature = try await sensor_read(sensorID, on: eventLoop).temperatureReading()
                        return (sensorID, sensorName, .success(temperature))
                    } catch {
                        return (sensorID, sensorName, .failure(error))
                    }
                }
                
                while let (sensorID, sensorName, result) = await group.next() {
                    let header = if let sensorName = sensorName {
                        "0x\(sensorID) (\(sensorName)):"
                    } else {
                        "0x\(sensorID):"
                    }
                    
                    let value = switch result {
                    case .success(.some(let temperature)): "\(temperature)°C"
                    case .success(.none): "sensor is disabled"
                    case .failure(let error as SensorReadError):
                        switch error {
                        case .invalidIPMIResponse: "invalid IPMI response"
                        case .sensorIsInaccessible: "sensor is inaccessible or missing"
                        }
                    case .failure(let error as ShellError):
                        switch error {
                        case .missingStdout, .missingStderr: "missing IPMI response"
                        case .unableToReadStdout, .unableToReadStderr: "unable to read IPMI response"
                        }
                    case .failure(let error as ShellCommandFailure): error.description
                    case .failure(let error): error.localizedDescription
                    }
                    
                    print("\(header) \(value)")
                }
            }
        }
    }
}


