import ArgumentParser

@main
public struct Fanctrl: AsyncParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "fanctrl",
        version: "0.0.0",
        shouldDisplay: true,
        groupedSubcommands: [],
        aliases: []
    )
    
    public init() { }
}
