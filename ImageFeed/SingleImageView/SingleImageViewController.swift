import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    var imageURL: URL! {
        didSet {
            guard isViewLoaded else { return }
            setImage()
        }
    }
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func didTapShareButton() {
        let share = UIActivityViewController(activityItems: [imageView.image], applicationActivities: nil)
        present(share, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.5
        setImage()
    }
    
    private func setImage() {
        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: imageURL) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let imageResult):
                self.rescaleAndCenterImageInScrollView(image: imageResult.image)
            case .failure:
                self.displayAlert()
            }
            UIBlockingProgressHUD.dismiss()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size

        // Calculate the scale needed to fit the entire image within the scroll view
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let initialScale = min(hScale, vScale)

        // Set the minimum and maximum zoom scales
        scrollView.minimumZoomScale = initialScale
        scrollView.maximumZoomScale = max(initialScale * 4, 1.0) // Adjust as needed

        // Set the initial zoom scale and content size
        scrollView.zoomScale = initialScale
        scrollView.contentSize = imageSize
        view.layoutIfNeeded()
        scrollView.layoutIfNeeded()

        // Center the image within the scroll view
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}

extension SingleImageViewController {
    private func displayAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )
        
        let dismissAction = UIAlertAction(
            title: "Отмена",
            style: .default
        ) { _ in
            alert.dismiss(animated: true)
        }
        
        let retryAction = UIAlertAction(
            title: "Да",
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }
            self.setImage()
        }
        alert.addAction(dismissAction)
        alert.addAction(retryAction)
        
        self.present(alert, animated: true)
    }
}
