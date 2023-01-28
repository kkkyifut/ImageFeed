import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    private let profileService = ProfileService.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    private var gradientAvatar: CAGradientLayer!
    private var gradientName: CAGradientLayer!
    private var gradientLogin: CAGradientLayer!
    private var gradientDescription: CAGradientLayer!
    private let animationGradient = AnimationGradient.shared
    
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "avatar"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private var nameLabel: UILabel!
    private var loginLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        createProfileImageAndLogin()
        createProfileDescription()
        exitButton()
        updateProfileDetails(profile: profileService.profile!)
        
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.DidChangeNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
        updateAvatar()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func updateAvatar() {                                   
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
            animationGradient.removeGradient(gradient: gradientAvatar)
        }
    }
    
    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name
        loginLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
        
        animationGradient.removeGradient(gradient: gradientName)
        animationGradient.removeGradient(gradient: gradientLogin)
        animationGradient.removeGradient(gradient: gradientDescription)
    }
    
    private func createProfileImageAndLogin() {
        let profileImage = UIImage(named: "placeholder")
        let profileImageView = UIImageView(image: profileImage)
        profileImageView.tintColor = UIColor(named: "YP Gray")
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileImageView)
        self.avatarImageView = profileImageView
        gradientAvatar = animationGradient.createGradient(width: 70, height: 70, cornerRadius: 35)
        self.avatarImageView.layer.addSublayer(gradientAvatar)
        
        let nameLabel = UILabel()
        nameLabel.text = "Екатерина Новикова"
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: UIFont.Weight.bold)
        nameLabel.textColor = UIColor(named: "YP White")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        self.nameLabel = nameLabel
        gradientName = animationGradient.createGradient(width: 223, height: 23, cornerRadius: 11.5)
        self.nameLabel.layer.addSublayer(gradientName)
        
        let loginLabel = UILabel()
        loginLabel.text = "@eva_elfie"
        loginLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        loginLabel.textColor = UIColor(named: "YP Gray")
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginLabel)
        self.loginLabel = loginLabel
        gradientLogin = animationGradient.createGradient(width: 89, height: 18, cornerRadius: 9)
        self.loginLabel.layer.addSublayer(gradientLogin)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            profileImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            loginLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            loginLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
        ])
    }
    
    private func createProfileDescription() {
        let description = UILabel()
        description.text = "Hello, my dear reviewer!"
        description.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        description.textColor = UIColor(named: "YP White")
        description.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(description)
        self.descriptionLabel = description
        gradientDescription = animationGradient.createGradient(width: 67, height: 18, cornerRadius: 9)
        self.descriptionLabel.layer.addSublayer(gradientDescription)
        
        NSLayoutConstraint.activate([
            description.topAnchor.constraint(equalTo: self.loginLabel.bottomAnchor, constant: 8),
            description.leadingAnchor.constraint(equalTo: self.loginLabel.leadingAnchor),
            description.trailingAnchor.constraint(equalTo: self.loginLabel.trailingAnchor),
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
    
    private func onLogout() {
        OAuth2TokenStorage().clearToken()
        WebViewViewController.clean()
        tabBarController?.dismiss(animated: true)
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Invalid Configuration") }
        window.rootViewController = SplashViewController()
    }
    
    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: "Выход из аккаунта",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        
        let agreeAction = UIAlertAction(
            title: "Да",
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.onLogout()
            }
        }
        
        let dismissAction = UIAlertAction(
            title: "Отмена",
            style: .default
        )
        
        alert.addAction(agreeAction)
        alert.addAction(dismissAction)
        
        present(alert, animated: true)
    }
    
//    func createGradient(width: CGFloat, height: CGFloat, cornerRadius: CGFloat) -> CAGradientLayer {
//        let gradient = CAGradientLayer()
//        gradient.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
//        gradient.locations = [0, 0.1, 0.3]
//        gradient.colors = [
//            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
//            UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
//            UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
//        ]
//        gradient.startPoint = CGPoint(x: 0, y: 0.5)
//        gradient.endPoint = CGPoint(x: 1, y: 0.5)
//        gradient.cornerRadius = cornerRadius
//        gradient.masksToBounds = true
//
//        let gradientChangeAnimation = CABasicAnimation(keyPath: "locations")
//        gradientChangeAnimation.duration = 1.0
//        gradientChangeAnimation.repeatCount = .infinity
//        gradientChangeAnimation.fromValue = [0, 0.1, 0.3]
//        gradientChangeAnimation.toValue = [0, 0.8, 1]
//        gradient.add(gradientChangeAnimation, forKey: "locationsChange")
//
//        return gradient
//    }
//
//    func removeGradient(gradient: CAGradientLayer) {
//        gradient.removeFromSuperlayer()
//    }
}
