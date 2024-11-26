import ArgumentParser
import IPMITool

extension Sensor: ExpressibleByArgument {
    public init?(argument: String) {
        if let match = argument.wholeMatch(of: /(0x)?(?<number>[0-9A-Fa-f]{2})/) {
            guard let sensorID = UInt8(match.output.number) else {
                return nil
            }
            self.init(rawValue: sensorID)
        }
        
        switch argument.lowercased() {
        case /amb(ient)?[-_ ]?(temp(erature)?)?/: self = .ambientTemperature
        case /planar[-_ ]?(temp(erature)?)?/: self = .planarTemperature
        default: break
        }
        
        return nil
    }
}
