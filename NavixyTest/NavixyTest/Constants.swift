import Foundation

enum Constants {
    enum API {
        static let baseURL = URL(string: "https://api.eu.navixy.com/v2")!
    }

    enum DemoCredentials {
        static let login = "demo-eu@navixy.com"
        static let password = "123456"
    }

    enum StorageKeys {
        static let sessionHash = "navixy.sessionHash"
    }
}
