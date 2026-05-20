import Foundation

enum Logger {
    static var debugEnabled = false

    static func d(_ tag: String, _ message: String) {
        guard debugEnabled else { return }
        print("[GatiFlow/\(tag)] \(message)")
    }

    static func e(_ tag: String, _ message: String) {
        print("[GatiFlow/\(tag)] ERROR: \(message)")
    }
}
