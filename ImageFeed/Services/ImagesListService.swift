import UIKit

final class ImagesListService {
    static let DidChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    static let shared = ImagesListService()
    private let storageToken = OAuth2TokenStorage()
    
    private (set) var photos: [Photo] = []
    private var task: URLSessionTask?
    private var lastLoadedPage: Int?
    
    init() {}
    
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        if task != nil { return }
        
        if var lastLoadedPage {
            self.lastLoadedPage! += 1
        } else {
            self.lastLoadedPage = 1
        }
        let token = storageToken.token ?? ""
        let page = lastLoadedPage ?? 1
        let request = makeRequest(token: token, page: page)

        let session = URLSession.shared
        let task = session.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let photos):
                    let photoViewModels = photos.map { Photo(decodedData: $0) }
                    self.photos.append(contentsOf: photoViewModels)
                    NotificationCenter.default.post(
                        name: ImagesListService.DidChangeNotification,
                        object: self
                    )
                case .failure(let error):
                    print(error)
                }
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }
    
    private func makeRequest(token: String, page: Int) -> URLRequest {
        guard let url = URL(string: defaultBaseURL + "photos?page=\(page)") else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

extension ImagesListService {
    enum LikeServiceError: Error {
        case raceCondition
    }
    
    func changeLike(photoId: String, isLike: Bool, indexPath: Int, _ completion: @escaping (Result<Photo, Error>) -> Void) {
        if task != nil {
            completion(.failure(LikeServiceError.raceCondition))
            return
        }
        
        let token = storageToken.token ?? ""
        let request = makeLikeRequest(token: token, photoId: photoId, isLike: isLike)
        
        let session = URLSession.shared
        let task = session.objectTask(for: request) { [weak self] (result: Result<LikePhotoResult, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let photoResult):
                self.photos[indexPath].isLiked = photoResult.photo.isLiked
                completion(.success(Photo(decodedData: photoResult.photo)))
            case .failure(let error):
                completion(.failure(error))
            }
            self.task = nil
        }
        self.task = task
        task.resume()
    }
    
    private func makeLikeRequest(token: String, photoId: String, isLike: Bool) -> URLRequest {
        guard let url = URL(string: defaultBaseURL + "photos/\(photoId)/like") else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = isLike ? "POST" : "DELETE"
        return request
    }
}

struct LikePhotoResult: Decodable {
    let photo: PhotoResult
}

struct PhotoResult: Decodable {
    let id: String
    let welcomeDescription: String?
    let urls: [String: String]
    let createdAt: String?
    let isLiked: Bool

    enum CodingKeys: String, CodingKey {
        case id, urls
        case createdAt = "created_at"
        case welcomeDescription = "description"
        case isLiked = "liked_by_user"
    }
}

struct Photo: Codable {
    let id: String
    let createdAt: String?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    var isLiked: Bool
    
    init(decodedData: PhotoResult) {
        self.id = decodedData.id
        self.createdAt = decodedData.createdAt
        self.welcomeDescription = decodedData.welcomeDescription
        self.thumbImageURL = decodedData.urls[UrlsResult.CodingKeys.thumbImageURL.rawValue]!
        self.largeImageURL = decodedData.urls[UrlsResult.CodingKeys.largeImageURL.rawValue]!
        self.isLiked = decodedData.isLiked
    }
}

struct UrlsResult: Codable {
    let thumbImageURL: String
    let largeImageURL: String
    
    enum CodingKeys: String, CodingKey {
        case thumbImageURL = "thumb"
        case largeImageURL = "full"
    }
}
