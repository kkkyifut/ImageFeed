import UIKit

final class AuthViewController: UIViewController {
    private let storyboardInstance = UIStoryboard(name: "Main", bundle: nil)
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let storageToken = OAuth2TokenStorage()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showWebViewSegueIdentifier else { return }
        guard let webViewViewController = segue.destination as? WebViewViewController else { return }
        webViewViewController.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        guard storageToken.token == nil else { return }
        OAuth2Service.shared.fetchAuthToken(code: code) { result in
            DispatchQueue.main.async { [self] in
                do {
                    let data = try result.get()
                    storageToken.token = data
                } catch let error {
                    print("Error: ", error)
                }
            }
        }
        let tabBarViewController = storyboardInstance.instantiateViewController(withIdentifier: "TabBarViewController")
        UIApplication.shared.windows.first?.rootViewController = tabBarViewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        dismiss(animated: true, completion: nil)
    }
}
