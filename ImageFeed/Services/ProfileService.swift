import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private(set) var profile: Profile?
    
    private enum NetworkError: Error {
        case codeError
    }
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        if lastCode == token { return }
        task?.cancel()
        lastCode = token
        
        let request = makeRequest(token: token)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let response = response as? HTTPURLResponse,
                   !(200...299).contains(response.statusCode) {
                    completion(.failure(NetworkError.codeError))
                    return
                }
                if let data = data {
                    do {
                        let decodedData = try JSONDecoder().decode(ProfileResult.self, from: data)
                        let profile = Profile(decodedData: decodedData)
                        print("profile", profile)
                        self.profile = profile
                        completion(.success(profile))
                        self.task = nil
                        if error != nil {
                            self.lastCode = nil
                        }
                    } catch let error {
                        completion(.failure(error))
                    }
                } else {
                    return
                }
            }
        }
        self.task = task
        task.resume()
    }
    
    private func makeRequest(token: String) -> URLRequest {
        guard let url = URL(string: currentUserURLString) else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

struct ProfileResult: Codable {
    let username, firstName, lastName, bio: String?
    let profileImage: [String:String]
    
    enum CodingKeys: String, CodingKey {
        case username = "username"
        case firstName = "first_name"
        case lastName = "last_name"
        case bio = "bio"
        case profileImage = "profile_image"
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
