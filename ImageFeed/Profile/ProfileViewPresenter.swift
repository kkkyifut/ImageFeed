import UIKit
import Kingfisher
import WebKit

public protocol ProfileViewPresenterProtocol {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func makeAlert() -> UIAlertController
}

final class ProfileViewPresenter: ProfileViewPresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    private let profileService = ProfileService.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    
    func viewDidLoad() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.DidChangeNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let self = self else { return }
                self.view?.updateAvatar()
            }
        view?.updateAvatar()
    }
    
    func makeAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: "Выход из аккаунта",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )

        let agreeAction = UIAlertAction(title: "Да", style: .default) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.view?.onLogout()
            }
        }
            
        let dismissAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        alert.addAction(agreeAction)
        alert.addAction(dismissAction)
        
        return alert
    }
}
