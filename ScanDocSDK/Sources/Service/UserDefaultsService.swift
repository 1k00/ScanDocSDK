import Foundation

private enum UserDefaultsEntry: String {

    case subClient
}

final class UserDefaultsService {

    @Atomic private var userDefaults = UserDefaults.standard

    @objc dynamic var subClient: String? {
        get {
            userDefaults.object(forKey: UserDefaultsEntry.subClient.rawValue) as? String
        }
        set {
            userDefaults.set(newValue, forKey: UserDefaultsEntry.subClient.rawValue)
        }
    }
}
