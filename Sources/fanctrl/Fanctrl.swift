import ArgumentParser

@main
public struct Fanctrl: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "fanctrl",
        version: "0.0.0",
        shouldDisplay: true,
        subcommands: [],
        groupedSubcommands: [
            CommandGroup(name: "Fans", subcommands: [SetFans.self]),
            CommandGroup(name: "Sensors", subcommands: [GetTemperature.self]),
        ],
        defaultSubcommand: nil,
        helpNames: .shortAndLong,
        aliases: []
    )
    
    public init() { }
}
