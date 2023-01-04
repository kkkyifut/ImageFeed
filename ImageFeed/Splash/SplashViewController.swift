import UIKit

final class SplashViewController: UIViewController {
    private let storyboardInstance = UIStoryboard(name: "Main", bundle: nil)
    private let storageToken = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard storageToken.token != nil else {
            showNextScreen(withID: "AuthViewController")
            return
        }
        fetchProfile(token: storageToken.token!)
    }
    
    private func showNextScreen(withID screenID: String) {
        let nextViewController = storyboardInstance.instantiateViewController(withIdentifier: screenID)
        UIApplication.shared.windows.first?.rootViewController = nextViewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    private func fetchProfile(token: String) {
        profileService.fetchProfile(token) { [weak self] result in
            DispatchQueue.main.async { [self] in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.profileImageService.fetchProfileImageURL(username: (self.profileService.profile?.username)!) { _ in
                    }
                    self.showNextScreen(withID: "TabBarViewController")
                case .failure:
                    let alert = UIAlertController(
                        title: "Что-то пошло не так",
                        message: "Не удалось войти в систему. Проверьте ваше интернет соединение",
                        preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "ОК", style: .default) { _ in
                        self.showNextScreen(withID: "SplashViewController")
                    }
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
            
//        }
    }
}
