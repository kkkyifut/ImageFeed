import Foundation
import Combine

final class ProfileImageService {
    static let shared = ProfileImageService()
    private let urlSession = URLSession.shared
    private var cancellable: AnyCancellable?
    private let storageToken = OAuth2TokenStorage()
    private(set) var avatarURL: String?
    
    func fetchProfileImageURL(username: String) -> AnyPublisher<String, Error> {
        assert(Thread.isMainThread)
        
        let request = makeRequest(token: storageToken.token!, username: username)
        
        let publisher = urlSession.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: UserResult.self, decoder: JSONDecoder())
            .map { decodedObject -> String in
                let avatarURL = ProfileImage(decodedData: decodedObject)
                return avatarURL.profileImage["large"] ?? ""
            }
            .handleEvents(receiveOutput: { [weak self] avatarURL in
                self?.avatarURL = avatarURL
                NotificationCenter.default.post(
                    name: .profileImageProviderNotification,
                    object: self,
                    userInfo: ["URL": avatarURL])
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        cancellable = publisher.sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error:", error)
                }
            },
            receiveValue: { _ in })
        
        return publisher
    }
    
    private func makeRequest(token: String, username: String) -> URLRequest {
        guard let url = URL(string: defaultBaseURLString + "/users/" + username) else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

struct UserResult: Codable {
    let profileImage: [String:String]
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImage: Codable {
    let profileImage: [String:String]
    
    init(decodedData: UserResult) {
        self.profileImage = decodedData.profileImage
    }
}
