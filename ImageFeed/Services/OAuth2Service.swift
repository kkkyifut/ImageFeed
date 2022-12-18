import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    
    private enum NetworkError: Error {
        case codeError
    }
    
    func fetchAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        var urlComponents = URLComponents(string: UnsplashAuthorizeURLString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: AccessKey),
            URLQueryItem(name: "client_secret", value: SecretKey),
            URLQueryItem(name: "redirect_uri", value: RedirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        let url = urlComponents.url!
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
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
                } catch let error {
                    completion(.failure(error))
                }
            } else {
                return
            }
        }
        task.resume()
    }
}
