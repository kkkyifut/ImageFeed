import UIKit

final class SplashViewController: UIViewController {
    private let storyboardInstance = UIStoryboard(name: "Main", bundle: nil)
    private let storageToken = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    
    private enum NetworkError: Error {
        case codeError
    }
    
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
                    UIBlockingProgressHUD.dismiss()
                    self.showNextScreen(withID: "TabBarViewController")
                case .failure:
                    UIBlockingProgressHUD.dismiss()
                    print("Error:", NetworkError.codeError)
                    break
                }
            }
        }
    }
}
