import Foundation
import os.log

/// A single JSON document in the App Group container, readable and writable by
/// the app and all three extensions.
///
/// Reads always hit the file system rather than an in-memory cache. That is
/// deliberate: `UserDefaults(suiteName:)` can serve a stale snapshot to an
/// extension that was launched while the app held the newer value, and a stale
/// read here would mean shielding the wrong apps. Access is wrapped in
/// `NSFileCoordinator` so a write from the shield-action extension cannot
/// interleave with one from the app.
public final class SharedFileStore<Value: Codable & Sendable>: @unchecked Sendable {

    private let fileName: String
    private let defaultValue: Value
    private let log = Logger(subsystem: "com.salahfirst.app", category: "SharedFileStore")

    /// Fallback used when the App Group is unavailable (Simulator without a
    /// signing team, unit tests). Keeps the app usable instead of crashing.
    private var inMemoryValue: Value
    private let lock = NSLock()

    public init(fileName: String, defaultValue: Value) {
        self.fileName = fileName
        self.defaultValue = defaultValue
        self.inMemoryValue = defaultValue
    }

    private var fileURL: URL? {
        AppGroup.containerURL?.appendingPathComponent(fileName)
    }

    /// Reads without file coordination, deliberately.
    ///
    /// Every write here is atomic, so a reader sees either the complete previous
    /// file or the complete new one — never a torn one. Coordination would buy
    /// nothing against that, and it costs a round trip to a system daemon.
    ///
    /// That round trip is the problem: the shield extensions are invoked
    /// synchronously, inside a tight sandbox, with very little time. When
    /// coordination fails there it fails silently, and a silent fall back to
    /// the default `ShieldState` puts the wrong prayer on the user's screen —
    /// which is exactly what happened on device before this changed.
    public func read() -> Value {
        guard let fileURL else {
            lock.lock(); defer { lock.unlock() }
            return inMemoryValue
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            // No file yet is normal on first run.
            return defaultValue
        }
        do {
            return try JSONDecoder.shared.decode(Value.self, from: data)
        } catch {
            // A decode failure means the file predates a model change. Falling
            // back to the default is safer than refusing to run: the app
            // rebuilds its state on the next foreground.
            log.error("Could not decode \(self.fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return defaultValue
        }
    }

    @discardableResult
    public func write(_ value: Value) -> Bool {
        guard let fileURL else {
            lock.lock(); defer { lock.unlock() }
            inMemoryValue = value
            return true
        }
        guard let data = try? JSONEncoder.shared.encode(value) else {
            log.error("Could not encode \(self.fileName, privacy: .public)")
            return false
        }

        var succeeded = false
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinationError) { url in
            do {
                try data.write(to: url, options: .atomic)
                succeeded = true
            } catch {
                log.error("Could not write \(self.fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        if let coordinationError {
            log.error("Coordination failed for \(self.fileName, privacy: .public): \(coordinationError.localizedDescription, privacy: .public)")
        }
        return succeeded
    }

    /// Read-modify-write under a single coordinated write, so two processes
    /// cannot both read the old value and clobber each other's change.
    @discardableResult
    public func mutate(_ transform: (inout Value) -> Void) -> Value {
        guard let fileURL else {
            lock.lock(); defer { lock.unlock() }
            transform(&inMemoryValue)
            return inMemoryValue
        }

        var result = defaultValue
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: fileURL, options: [], error: &coordinationError) { url in
            var value = defaultValue
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder.shared.decode(Value.self, from: data) {
                value = decoded
            }
            transform(&value)
            if let data = try? JSONEncoder.shared.encode(value) {
                try? data.write(to: url, options: .atomic)
            }
            result = value
        }
        if let coordinationError {
            log.error("Coordination failed for \(self.fileName, privacy: .public): \(coordinationError.localizedDescription, privacy: .public)")
        }
        return result
    }
}

extension JSONEncoder {
    /// ISO-8601 dates keep the shared files readable by a human debugging the
    /// container, and side-step any locale sensitivity.
    static let shared: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}

extension JSONDecoder {
    static let shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
