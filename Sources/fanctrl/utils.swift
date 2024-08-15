import Foundation

internal var standardError: FileHandle {
    get { FileHandle.standardError }
    set { }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        self.write(data)
    }
}
