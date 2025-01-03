import Foundation

public class AppLogger {
    
    static let shared = AppLogger()
    
    private var isLoggingEnabled: Bool = false
    
    private init() {}
    
    func setLoggingEnabled(_ isEnabled: Bool) {
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
