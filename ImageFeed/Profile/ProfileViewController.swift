import UIKit

final class ProfileViewController: UIViewController {
    @IBOutlet weak private var avatarImageView: UIImageView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var loginNameLabel: UILabel!
    @IBOutlet weak private var descriptionLabel: UILabel!
    
    @IBOutlet weak private var logoutButton: UIButton!
    
    @IBAction private func didTapLogoutButton(_ sender: UIButton) {
        
    }
    
}
