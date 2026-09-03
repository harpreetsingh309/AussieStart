import Foundation
import OSLog

/// Loud, unmissable tracing for the purchase flow.
///
/// Writes the same line three ways because each fails in a different
/// situation: `print` shows in Xcode's console only while the debugger is
/// attached; `NSLog` reaches Console.app and the device log even when it is
/// not; `Logger` is filterable by subsystem. The line is also kept in a small
/// ring buffer that the paywall can display, so a device can be diagnosed with
/// no Mac involved at all.
@MainActor
enum StoreLog {
    /// Change this whenever you want to prove which build is on the device.
    static let buildMarker = "SK-DIAG-1"

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.aussiestart.app",
        category: "StoreKit"
    )

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private(set) static var events: [String] = []

    static func event(_ message: String) {
        let line = "\(formatter.string(from: .now))  \(message)"
        events.append(line)
        if events.count > 80 { events.removeFirst(events.count - 80) }

        print("🟣 [AussieStart/StoreKit] \(line)")
        NSLog("[AussieStart/StoreKit] %@", line)
        logger.notice("\(line, privacy: .public)")
    }

    static func reset() {
        events.removeAll()
    }

    /// Printed once at launch. If you do not see this line, the device is not
    /// running this build — which is itself the answer.
    static func launchBanner() {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let bundleID = Bundle.main.bundleIdentifier ?? "nil"
        #if DEBUG
        let config = "DEBUG"
        #else
        let config = "RELEASE"
        #endif
        event("=== AussieStart launched · \(version) (\(build)) · \(config) · bundle=\(bundleID) · marker=\(buildMarker) ===")
    }

    static var transcript: String {
        events.isEmpty ? "No events recorded yet." : events.joined(separator: "\n")
    }
}
