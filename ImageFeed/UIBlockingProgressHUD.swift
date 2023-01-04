import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    static let shared = UIBlockingProgressHUD()
    
    private init() {}
    
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.show()
    }
    
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}
