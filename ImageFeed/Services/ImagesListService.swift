import UIKit

final class ImagesListService {
    static let shared = ImagesListService()
    private (set) var photos: [Photo] = []
    static let DidChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    private var task: URLSessionTask?
    private var lastLoadedPage: Int?
    
    private init() {}
    
    func fetchPhotosNextPage(_ token: String, completion: @escaping (Result<[Photo], Error>) -> Void) {
        assert(Thread.isMainThread)
        lastLoadedPage = lastLoadedPage == nil ? 1 : lastLoadedPage! + 1
        let request = makeRequest(token: token, page: lastLoadedPage!)
        let session = URLSession.shared
        let task = session.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            switch result {
            case .success(let photos):
                for photo in photos {
                    let photo = Photo(decodedData: photo)
                    self?.photos.append(photo)
                }
                completion(.success(self?.photos ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        self.task = task
        task.resume()
    }
    
    private func makeRequest(token: String, page: Int) -> URLRequest {
        guard let url = URL(string: defaultBaseURL + "/photos?page=\(page)") else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        lastLoadedPage! += 1
        return request
    }
}

struct PhotoResult: Codable {
    let id, thumbImageURL, largeImageURL: String
    let welcomeDescription: String?
    let size: CGSize
    let createdAt: Date?
    let isLiked: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case size = "size"
        case createdAt = "created_at"
        case welcomeDescription = "description"
        case thumbImageURL = "thumb"
        case largeImageURL = "full"
        case isLiked = "liked_by_user"
    }
}

struct Photo: Codable {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
    
    init(decodedData: PhotoResult) {
        self.id = decodedData.id
        self.size = decodedData.size
        self.createdAt = decodedData.createdAt
        self.welcomeDescription = decodedData.welcomeDescription
        self.thumbImageURL = decodedData.thumbImageURL
        self.largeImageURL = decodedData.largeImageURL
        self.isLiked = decodedData.isLiked
    }
}
