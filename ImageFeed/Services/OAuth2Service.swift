import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    private enum NetworkError: Error {
        case codeError
    }
    
    func fetchAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        if lastCode == code { return }
        task?.cancel()
        lastCode = code
        let request = makeRequest(code: code)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            print("code", code)
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
                        let decodedData = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                        completion(.success(decodedData.accessToken))
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
    
    private func makeRequest(code: String) -> URLRequest {
        var urlComponents = URLComponents(string: unsplashTokenURLString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: accessKey),
            URLQueryItem(name: "client_secret", value: secretKey),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}
