public struct SensorState: Hashable, Sendable, Codable {
    public var eventMessagesEnabled: Bool
    public var valueScanningEnabled: Bool
    
    public init(eventMessages: Bool, valueScanning: Bool) {
        self.eventMessagesEnabled = eventMessages
        self.valueScanningEnabled = valueScanning
    }
}
