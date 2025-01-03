import ArgumentParser

@main
public struct Fanctrl: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "fanctrl",
        version: "0.0.0",
        shouldDisplay: true,
        subcommands: [SetFans.self, Sensors.self],
        groupedSubcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong,
        aliases: []
    )
    
    public init() { }
}
