import UIKit
import ProgressHUD
import Combine

final class AuthViewController: UIViewController {
    private let storyboardInstance = UIStoryboard(name: "Main", bundle: nil)
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let storageToken = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private var cancellable: AnyCancellable?
    
    private enum NetworkError: Error {
        case codeError
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard let webViewViewController = segue.destination as? WebViewViewController else { return }
            let authHelper = AuthHelper()
            let webViewPresenter = WebViewPresenter(authHelper: authHelper)
            webViewViewController.presenter = webViewPresenter
            webViewPresenter.view = webViewViewController
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        guard storageToken.token == nil else { return }
        UIBlockingProgressHUD.show()
        OAuth2Service.shared.fetchAuthToken(code: code) { result in
            DispatchQueue.main.async { [self] in
                do {
                    let data = try result.get()
                    storageToken.token = data
                    self.fetchProfile(token: storageToken.token!)
                } catch let error {
                    print("Error: ", error)
                }
                UIBlockingProgressHUD.dismiss()
            }
        }
    }
    
    private func fetchProfile(token: String) {
        cancellable = profileService.fetchProfile(token)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        UIBlockingProgressHUD.dismiss()
                        print("Error:", error)
                        break
                }
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.transitionToTabBar()
                UIBlockingProgressHUD.dismiss()
            })
    }
    
    private func transitionToTabBar() {
        let tabBarViewController = storyboardInstance.instantiateViewController(withIdentifier: "TabBarViewController")
        UIApplication.shared.windows.first?.rootViewController = tabBarViewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        dismiss(animated: true, completion: nil)
    }
}
