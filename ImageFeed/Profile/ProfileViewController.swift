import UIKit

final class ProfileViewController: UIViewController {
    private var avatarImageView: UIImageView!
    private var nameLabel: UILabel!
    private var loginLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton!
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor(named: "YP Black")
        createProfileImageAndLogin()
        createProfileDescription()
        exitButton()
    }
    
    private func createProfileImageAndLogin() {
        let profileImage = UIImage(named: "avatar")
        let profileImageView = UIImageView(image: profileImage)
        profileImageView.tintColor = UIColor(named: "YP Gray")
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.tag = 1
        view.addSubview(profileImageView)
        self.avatarImageView = profileImageView
        
        let nameLabel = UILabel()
        nameLabel.text = "Екатерина Новикова"
        nameLabel.font = UIFont(name: "YSDisplay-Medium", size: 23.0)
        nameLabel.font = nameLabel.font.withSize(23)
        nameLabel.textColor = UIColor(named: "YP White")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        self.nameLabel = nameLabel
        
        let loginLabel = UILabel()
        loginLabel.text = "@eva_elfie"
        loginLabel.font = UIFont(name: "YSDisplay-Medium", size: 13.0)
        loginLabel.textColor = UIColor(named: "YP Gray")
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginLabel)
        self.loginLabel = loginLabel
        
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
        description.font = UIFont(name: "YSDisplay-Medium", size: 13.0)
        description.textColor = UIColor(named: "YP White")
        description.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(description)
        self.descriptionLabel = description
        
        NSLayoutConstraint.activate([
            description.topAnchor.constraint(equalTo: self.loginLabel.bottomAnchor, constant: 8),
            description.leadingAnchor.constraint(equalTo: self.loginLabel.leadingAnchor),
            description.trailingAnchor.constraint(equalTo: self.loginLabel.trailingAnchor),
        ])
    }
    
    private func exitButton() {
        let exitButton = UIButton.systemButton(
            with: UIImage(systemName: "ipad.and.arrow.forward")!,
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
        let viewImage = view.viewWithTag(1) as! UIImageView
        viewImage.image = UIImage(systemName: "person.crop.circle.fill")
        nameLabel?.removeFromSuperview()
        nameLabel = nil
        loginLabel?.removeFromSuperview()
        loginLabel = nil
        descriptionLabel?.removeFromSuperview()
        descriptionLabel = nil
    }
}
