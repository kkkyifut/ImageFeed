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
        lastLoadedPage = lastLoadedPage == nil ? 1 : lastLoadedPage! + 1
        let request = makeRequest(token: storageToken.token!, page: lastLoadedPage!)
        let session = URLSession.shared
        let task = session.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            switch result {
            case .success(let photos):
                for photo in photos {
                    let photo = Photo(decodedData: photo)
                    self?.photos.append(photo)
//                    print("photo", photo)
                }
                NotificationCenter.default.post(
                    name: ImagesListService.DidChangeNotification,
                    object: self
                )
            case .failure(let error):
                print(error)
            }
        }
        self.task = task
        task.resume()
    }
    
    private func makeRequest(token: String, page: Int) -> URLRequest {
        guard let url = URL(string: defaultBaseURL + "photos?page=\(page)") else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("urlMakeRequest", url)
        return request
    }
}

struct PhotoResult: Codable {
    let id: String
    let welcomeDescription: String?
    let urls: [String: String]
//    let size: CGSize
    let createdAt: String?
    let isLiked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case urls
//        case size
        case createdAt = "created_at"
        case welcomeDescription = "description"
        case isLiked = "liked_by_user"
    }
}

struct Photo: Codable {
    let id: String
//    let size: CGSize
    let createdAt: String?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
    
    init(decodedData: PhotoResult) {
        self.id = decodedData.id
//        self.size = decodedData.size
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
