import UIKit
import Combine

final class SplashViewController: UIViewController {
    private let storyboardInstance = UIStoryboard(name: "Main", bundle: nil)
    private let storageToken = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private var cancellable: AnyCancellable?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(named: "YP Black")
        createSplashImage()
    }
    
    private func createSplashImage() {
        let imageView = UIImageView(image: UIImage(named: "Vector"))
        self.view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let token = storageToken.token else {
            showNextScreen(withID: "AuthViewController")
            return
        }

        fetchProfile(token: token)
    }
    
    private func showNextScreen(withID screenID: String) {
        let nextViewController = storyboardInstance.instantiateViewController(withIdentifier: screenID)
        UIApplication.shared.windows.first?.rootViewController = nextViewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    private func fetchProfile(token: String) {
        cancellable = profileService.fetchProfile(token)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                    case .finished:
                        break
                    case .failure:
                        let alert = UIAlertController(
                            title: "Что-то пошло не так",
                            message: "Не удалось войти в систему. Проверьте ваше интернет соединение",
                            preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self.showNextScreen(withID: "SplashViewController")
                        }
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        UIBlockingProgressHUD.dismiss()
                }
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                if let username = self.profileService.profile?.username {
                    self.profileImageService.fetchProfileImageURL(username: username) { _ in }
                }
                self.showNextScreen(withID: "TabBarViewController")
                UIBlockingProgressHUD.dismiss()
            })
    }
}
