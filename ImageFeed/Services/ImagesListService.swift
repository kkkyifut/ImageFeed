import UIKit
import Combine

final class ImagesListService {
    static let shared = ImagesListService()
    private let storageToken = OAuth2TokenStorage()
    private let urlSession = URLSession.shared
    
    private (set) var photos: [Photo] = []
    private var task: URLSessionTask?
    private var cancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var lastLoadedPage: Int = 0
    
    init() {}
    
    enum ServiceError: Error {
        case emptyToken
    }

    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        
        lastLoadedPage += 1
        
        guard let token = storageToken.token else {
            print(ServiceError.emptyToken)
            return
        }
        
        let request = makeRequest(token: token, page: lastLoadedPage, per_page: 20)
        
        urlSession.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [PhotoResult].self, decoder: JSONDecoder())
            .map { photos -> [Photo] in
                return photos.map { Photo(decodedData: $0) }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            }, receiveValue: { [weak self] photoViewModels in
                guard let self = self else { return }
                self.photos.append(contentsOf: photoViewModels)
                NotificationCenter.default.post(
                    name: .imagesListServiceNotification,
                    object: self
                )
            })
            .store(in: &cancellables)
    }
    
    private func makeRequest(token: String, page: Int, per_page: Int = 10) -> URLRequest {
        guard let url = URL(string: defaultBaseURLString + "photos?page=\(page)&per_page=\(per_page)") else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

extension ImagesListService {
    enum LikeServiceError: Error {
        case raceCondition
    }
    
    func changeLike(photoId: String, isLike: Bool, indexPath: Int) -> AnyPublisher<Photo, Error> {
        guard let token = storageToken.token else {
            return Fail(error: ServiceError.emptyToken)
                .eraseToAnyPublisher()
        }
        
        let request = makeLikeRequest(token: token, photoId: photoId, isLike: isLike)
        
        let publisher = urlSession.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: LikePhotoResult.self, decoder: JSONDecoder())
            .map { result -> Photo in
                self.photos[indexPath].isLiked = result.photo.isLiked
                return Photo(decodedData: result.photo)
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
    
    private func makeLikeRequest(token: String, photoId: String, isLike: Bool) -> URLRequest {
        guard let url = URL(string: defaultBaseURLString + "photos/\(photoId)/like") else { fatalError("Failed to create URL") }
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
    let width: CGFloat
    let height: CGFloat
    let welcomeDescription: String?
    let urls: [String: String]
    let createdAt: String?
    let isLiked: Bool

    enum CodingKeys: String, CodingKey {
        case id, urls, width, height
        case createdAt = "created_at"
        case welcomeDescription = "description"
        case isLiked = "liked_by_user"
    }
}

struct Photo: Codable {
    let id: String
    let width: CGFloat
    let height: CGFloat
    let createdAt: String?
    let welcomeDescription: String?
    let thumbImageURL: String
    let smallImageURL: String
    let regularImageURL: String
    let largeImageURL: String
    var isLiked: Bool
    
    init(decodedData: PhotoResult) {
        self.id = decodedData.id
        self.width = decodedData.width
        self.height = decodedData.height
        self.createdAt = decodedData.createdAt
        self.welcomeDescription = decodedData.welcomeDescription
        self.thumbImageURL = decodedData.urls[UrlsResult.CodingKeys.thumbImageURL.rawValue]!
        self.smallImageURL = decodedData.urls[UrlsResult.CodingKeys.smallImageURL.rawValue]!
        self.regularImageURL = decodedData.urls[UrlsResult.CodingKeys.regularImageURL.rawValue]!
        self.largeImageURL = decodedData.urls[UrlsResult.CodingKeys.largeImageURL.rawValue]!
        self.isLiked = decodedData.isLiked
    }
}

struct UrlsResult: Codable {
    let thumbImageURL: String
    let smallImageURL: String
    let regularImageURL: String
    let largeImageURL: String
    
    enum CodingKeys: String, CodingKey {
        case thumbImageURL = "thumb"
        case smallImageURL = "small"
        case regularImageURL = "regular"
        case largeImageURL = "full"
    }
}
