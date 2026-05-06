import Foundation

final class SessionStore {
    private let defaults: UserDefaults
    private let sessionHashKey = Constants.StorageKeys.sessionHash

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var sessionHash: String? {
        get { defaults.string(forKey: sessionHashKey) }
        set { defaults.set(newValue, forKey: sessionHashKey) }
    }

    func clear() {
        defaults.removeObject(forKey: sessionHashKey)
    }
}
