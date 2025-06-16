import Foundation

class GameLogger {
    
    static let shared = GameLogger()
    
    enum LogLevel: String {
        case info = "INFO"
        case debug = "DEBUG"
        case warning = "WARN"
        case error = "ERROR"
    }
    
    private var logFile: URL?
    private let dateFormatter = DateFormatter()
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Logger Error: Failed to find documents directory.")
            return
        }
        
        logFile = documentsDirectory.appendingPathComponent("ludo_game_log.txt")
        
        // Start a new log file for each new logger instance (i.e., each app launch)
        clearLogFile()
    }
    
    /// The URL of the log file, which can be used with SwiftUI's ShareLink.
    var logFileURL: URL? {
        return logFile
    }
    
    /// Logs a message to the console and to the log file.
    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] - \(message)\n"
        
        // Print to console for real-time debugging
        print(logMessage, terminator: "")
        
        // Write to the log file
        guard let logFile = logFile else { return }
        
        do {
            // If file doesn't exist, this write will create it.
            // If it does exist, we need to append.
            if FileManager.default.fileExists(atPath: logFile.path) {
                let fileHandle = try FileHandle(forWritingTo: logFile)
                fileHandle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try logMessage.data(using: .utf8)?.write(to: logFile, options: .atomic)
            }
        } catch {
            print("Logger Error: Failed to write to log file: \(error)")
        }
    }
    
    /// Clears the log file to start fresh for a new session.
    func clearLogFile() {
        guard let logFile = logFile else { return }
        do {
            try "".write(to: logFile, atomically: true, encoding: .utf8)
            // Initial log message is written by the first log() call.
        } catch {
            print("Logger Error: Failed to clear log file: \(error)")
        }
    }
} 
