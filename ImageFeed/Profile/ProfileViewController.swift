import UIKit
import Kingfisher

public protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfileViewPresenterProtocol { get set }
    func updateAvatar()
    func onLogout()
}

final class ProfileViewController: UIViewController, ProfileViewControllerProtocol {
    private let profileService = ProfileService.shared
    private var gradientAvatar: CAGradientLayer!
    private var gradientName: CAGradientLayer!
    private var gradientLogin: CAGradientLayer!
    private var gradientDescription: CAGradientLayer!
    private let animationGradient = AnimationGradientFactory.shared

    lazy var presenter: ProfileViewPresenterProtocol = {
        return ProfileViewPresenter()
    }()
    
    lazy var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView(image: UIImage(named: "placeholder"))
        avatarImageView.tintColor = UIColor(named: "YP Gray")
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        return avatarImageView
    }()
    
    private let nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.text = "Екатерина Новикова"
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: UIFont.Weight.bold)
        nameLabel.textColor = UIColor(named: "YP White")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        return nameLabel
    }()
    
    private let loginLabel: UILabel = {
        let loginLabel = UILabel()
        loginLabel.text = "@eva_elfie"
        loginLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        loginLabel.textColor = UIColor(named: "YP Gray")
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        return loginLabel
    }()
    
    private let descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Hello, my dear reviewer!"
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        descriptionLabel.textColor = UIColor(named: "YP White")
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        return descriptionLabel
    }()
    
    private var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.view = self
        presenter.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        createProfileImageAndLogin()
        createProfileDescription()
        exitButton()
        updateProfileDetails(profile: profileService.profile)
        
        updateAvatar()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    internal func updateAvatar() {
        guard let profileImageURL = ProfileImageService.shared.avatarURL,
              let url = URL(string: profileImageURL) else { return }
        let cache = ImageCache.default
        cache.clearMemoryCache()
        cache.clearDiskCache()
        
        let processor = RoundCornerImageProcessor(cornerRadius: avatarImageView.frame.width)
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"), options: [.processor(processor)]) { [self] result in
            switch result {
            case .success(let value):
                print("Аватарка \(value.image) была успешно загружена и заменена в профиле")
            case .failure(let error):
                print(error)
            }
            gradientAvatar.removeFromSuperlayer()
        }
    }
    
    private func updateProfileDetails(profile: Profile?) {
        guard let profile = profile else { return }
        nameLabel.text = profile.name
        loginLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
        
        gradientName.removeFromSuperlayer()
        gradientLogin.removeFromSuperlayer()
        gradientDescription.removeFromSuperlayer()
    }
    
    private func createProfileImageAndLogin() {
//        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        gradientAvatar = animationGradient.createGradient(width: 70, height: 70, cornerRadius: 35)
        self.avatarImageView.layer.addSublayer(gradientAvatar)
        
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        gradientName = animationGradient.createGradient(width: 223, height: 23, cornerRadius: 11.5)
        self.nameLabel.layer.addSublayer(gradientName)
        
//        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginLabel)
        gradientLogin = animationGradient.createGradient(width: 89, height: 18, cornerRadius: 9)
        self.loginLabel.layer.addSublayer(gradientLogin)
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            loginLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            loginLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
        ])
    }
    
    private func createProfileDescription() {
        view.addSubview(descriptionLabel)
        gradientDescription = animationGradient.createGradient(width: 67, height: 18, cornerRadius: 9)
        self.descriptionLabel.layer.addSublayer(gradientDescription)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: self.loginLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: self.loginLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: self.loginLabel.trailingAnchor),
        ])
    }
    
    private func exitButton() {
        let exitButton = UIButton.systemButton(
            with: UIImage(named: "ipad.and.arrow.forward")!,
            target: self,
            action: #selector(Self.didTapLogoutButton))
        exitButton.tintColor = UIColor(named: "YP Red")
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exitButton)
        self.logoutButton = exitButton
        
        NSLayoutConstraint.activate([
            exitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            exitButton.centerYAnchor.constraint(equalTo: self.avatarImageView.centerYAnchor),
        ])
    }
    
    @objc func didTapLogoutButton(_ sender: UIButton) {
        showLogoutAlert()
    }
    
    internal func onLogout() {
        OAuth2TokenStorage().clearToken()
        WebViewViewController.clean()
        tabBarController?.dismiss(animated: true)
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Invalid Configuration") }
        window.rootViewController = SplashViewController()
    }
    
    private func showLogoutAlert() {
        let alert = presenter.makeAlert()
        present(alert, animated: true)
    }    
}
