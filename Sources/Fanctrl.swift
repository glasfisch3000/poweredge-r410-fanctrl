import ArgumentParser

@main
public struct Fanctrl: AsyncParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "fanctrl",
        version: "0.0.0",
        shouldDisplay: true,
        subcommands: [SetFans.self],
        groupedSubcommands: [],
        defaultSubcommand: SetFans.self,
        aliases: []
    )
    
    public init() { }
}
