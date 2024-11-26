import ArgumentParser

public struct Sensors: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "sensors",
        version: "0.0.0",
        shouldDisplay: true,
        subcommands: [GetTemperature.self, SensorsEnable.self],
        groupedSubcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong,
        aliases: []
    )
    
    public init() { }
}
