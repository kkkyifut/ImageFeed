import Foundation
import Combine

final class ProfileService {
    static let shared = ProfileService()
    private let urlSession = URLSession.shared
    private var cancellable: AnyCancellable?
    private(set) var profile: Profile?
    
    private init() {}
    
    func fetchProfile(_ token: String) -> AnyPublisher<Profile, Error> {
        assert(Thread.isMainThread)
        
        let request = makeRequest(token: token)
        
        let publisher = urlSession.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ProfileResult.self, decoder: JSONDecoder())
            .map { decodedObject -> Profile in
                let profile = Profile(decodedData: decodedObject)
                self.profile = profile
                return profile
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        cancellable = publisher.sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print("Error:", error)
            }
        }, receiveValue: { _ in })
        
        return publisher
    }
    
    private func makeRequest(token: String) -> URLRequest {
        guard let url = URL(string: defaultBaseURLString + "/me") else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

struct ProfileResult: Codable {
    let username, firstName, lastName, bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username = "username"
        case firstName = "first_name"
        case lastName = "last_name"
        case bio = "bio"
    }
}

struct Profile: Codable {
    let username, name, loginName, bio: String?
    
    init(decodedData: ProfileResult) {
        self.username = decodedData.username
        self.name = (decodedData.firstName ?? "") + " " + (decodedData.lastName ?? "")
        self.loginName = "@" + (decodedData.username ?? "")
        self.bio = decodedData.bio
    }
}
