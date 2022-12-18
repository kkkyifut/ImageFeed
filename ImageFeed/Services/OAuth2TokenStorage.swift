import Foundation

final class OAuth2TokenStorage {
    private let storage = UserDefaults.standard
    
    private enum Keys: String {
        case bearerToken
    }
    
    var token: String? {
        get {
            loadUserDefaults(for: .bearerToken, as: String.self)
        }
        set {
            saveUserDefaults(value: newValue, at: .bearerToken)
        }
    }
    
    private func loadUserDefaults<T: Codable>(for key: Keys, as dataType: T.Type) -> T? {
        guard let data = storage.data(forKey: key.rawValue),
              let count = try? JSONDecoder().decode(dataType.self, from: data) else {
            return nil
        }
        return count
    }
    
    private func saveUserDefaults<T: Codable>(value: T, at key: Keys) {
        guard let data = try? JSONEncoder().encode(value) else {
            print("Failed save data to UserDefaults")
            return
        }
        storage.set(data, forKey: key.rawValue)
    }
}
