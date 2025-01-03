import Foundation

public class AppLogger {
    
    public static let shared = AppLogger()
    
    public var isLoggingEnabled: Bool = true
    
    private init() {}
    
    public func setLoggingEnabled(_ isEnabled: Bool) {
        isLoggingEnabled = isEnabled
    }
    
    func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isLoggingEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        print("[\(level.rawValue.uppercased())] \(fileName):\(line) \(function) - \(message)")
    }
}

enum LogLevel: String {
    case debug
    case info
    case warning
    case error
}
