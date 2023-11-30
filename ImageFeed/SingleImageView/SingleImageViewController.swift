import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    var interactor: Interactor? = nil
    var onDismiss: (() -> Void)?
    var initialFrame: CGRect = .zero
    private var transitionPointY: CGFloat = .zero
    private var transitionPointX: CGFloat = .zero
    private var is2xZoomed = false
    
    var imageURL: URL! {
        didSet {
            guard isViewLoaded else { return }
            setImage()
        }
    }
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBAction private func didTapBackButton() {
        disappearingControlButtons()
        
        let scale = (imageView.frame.width / imageView.frame.height) > 1 ? 1.0 : 2.0
        self.scrollView.minimumZoomScale /= scale
        
        let duration = 0.25
        
        UIView.animate(withDuration: duration, animations: { [weak self] in
            guard let self = self else { return }
            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale / scale, animated: true)
            self.scrollView.transform = CGAffineTransform(translationX: -self.transitionPointX, y: -self.transitionPointY)
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.onDismiss?()
            UIView.animate(withDuration: duration * 0.7, animations: {
                self.scrollView.alpha = 0
            }, completion: { _ in
                self.dismiss(animated: true, completion: nil)
                self.view.removeFromSuperview()
            })
        })
    }
    
    @IBAction private func handleGesture(sender: UIPanGestureRecognizer) {
        guard !is2xZoomed else { return }
        
        let percentThreshold: CGFloat = 0.3
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)

        guard let interactor = interactor else { return }
        
        switch sender.state {
            case .began:
                interactor.hasStarted = true
            case .changed:
                let shouldFinish = progress > percentThreshold || abs(verticalMovement) > percentThreshold
                interactor.shouldFinish = shouldFinish
                scrollView.transform = CGAffineTransform(translationX: 0, y: translation.y)
                transitionPointY = scrollView.center.y - initialFrame.origin.y
                transitionPointX = scrollView.center.x - initialFrame.origin.x
                
                let alpha = progress > 0 ? 1.0 - (progress / percentThreshold) : 1.0 - abs(verticalMovement) / percentThreshold
                self.view.backgroundColor = UIColor(named: "YP Black")?.withAlphaComponent(alpha)
                UIView.animate(withDuration: 0.2) {
                    self.backButton.alpha = 0
                    self.shareButton.alpha = 0
                }
            case .cancelled, .ended:
                interactor.hasStarted = false
                if interactor.shouldFinish {
                    interactor.finish()
                    didTapBackButton()
                } else {
                    appearingControlButtons()
                    interactor.cancel()
                }
            default:
                break
        }
    }
    
    @IBAction private func doubleTapGesture(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: imageView)
        let scrollSize = scrollView.bounds.size

        let scale = scrollView.minimumZoomScale * 3
        let size = CGSize(width: scrollSize.width / scale, height: scrollSize.height / scale)
        let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        }
    }
    
    
    @IBAction private func didTapShareButton() {
        guard let imageToSave = imageView.image else { return }
        
        let share = UIActivityViewController(activityItems: [imageToSave], applicationActivities: nil)
        present(share, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func appearingControlButtons() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.scrollView.transform = .identity
            self.view.backgroundColor = UIColor(named: "YP Black")
            self.backButton.alpha = 1
            self.shareButton.alpha = 1
        }
    }
    
    private func disappearingControlButtons() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = .clear
            self.backButton.alpha = 0
            self.shareButton.alpha = 0
        }
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
        is2xZoomed = scrollView.zoomScale > scrollView.minimumZoomScale * 2
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let initialScale = getInitialScaleForZoom(image: image)

        scrollView.minimumZoomScale = initialScale
        scrollView.maximumZoomScale = max(initialScale * 4, 1.0)

        // Set the initial zoom scale and content size
        scrollView.zoomScale = initialScale
        scrollView.contentSize = image.size
        view.layoutIfNeeded()
        scrollView.layoutIfNeeded()

        // Center the image within the scroll view
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
        
        transitionPointY = scrollView.center.y - initialFrame.origin.y
        transitionPointX = scrollView.center.x - initialFrame.origin.x
    }
    
    private func getInitialScaleForZoom(image: UIImage) -> CGFloat {
        let visibleRectSize = scrollView.bounds.size

        let hScale = visibleRectSize.width / image.size.width
        let vScale = visibleRectSize.height / image.size.height
        let initialScale = min(hScale, vScale)
        
        return initialScale
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
