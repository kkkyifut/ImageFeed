import UIKit

final class AuthViewController: UIViewController {
    private let ShowWebViewSegueIdentifier = "ShowWebView"
    private let storageToken = OAuth2TokenStorage()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowWebViewSegueIdentifier {
            guard let webViewViewController = segue.destination as? WebViewViewController
            else {
                fatalError("Failed to prepare for \(ShowWebViewSegueIdentifier)")
            }
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
        guard storageToken.token != nil else {
            OAuth2Service.shared.fetchAuthToken(code: code) { result in
                DispatchQueue.main.async { [self] in
                    do {
                        let data = try result.get()
                        storageToken.token = data
                    } catch let error {
                        print(error)
                    }
                }
            }
            return
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}
