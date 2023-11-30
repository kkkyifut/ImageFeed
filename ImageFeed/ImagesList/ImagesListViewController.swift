import UIKit
import Kingfisher
import Combine

protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol { get set }
    func updateCollectionViewAnimated()
}

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    private let ShowSingleImageSegueIdentifier = "ShowSingleImage"
    private let storyboardInstance = UIStoryboard(name: "Main", bundle: nil)
    private let imagesListService = ImagesListService.shared
    private let interactor = Interactor()
    private var cancellables = Set<AnyCancellable>()
    private let storageToken = OAuth2TokenStorage()
    private let animationGradient = AnimationGradientFactory.shared
    var photos: [Photo] = []
    
    private lazy var dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate
        return formatter
    }()
    
    lazy var presenter: ImagesListPresenterProtocol = {
        return ImagesListPresenter()
    } ()
    
    @IBOutlet private var collectionView: UICollectionView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        presenter.view = self
        presenter.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .imagesListServiceNotification, object: nil)
    }
    
    func updateCollectionViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        if oldCount != newCount {
            collectionView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { IndexPath(item: $0, section: 0) }
                collectionView.insertItems(at: indexPaths)
            } completion: { _ in }
        }
    }
}

extension ImagesListViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactor.hasStarted ? interactor : .none
    }
}


extension ImagesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let singleImageVC = storyboardInstance.instantiateViewController(identifier: "SingleImageViewController") as! SingleImageViewController
        singleImageVC.hidesBottomBarWhenPushed = true
        singleImageVC.modalPresentationStyle = .overFullScreen
        
        let rectOfCellInCollectionView = collectionView.cellForItem(at: indexPath)!.frame
        collectionView.cellForItem(at: indexPath)?.contentView.alpha = 0
        
        let initialFrame = collectionView.convert(rectOfCellInCollectionView, to: view)
        let photo = photos[indexPath.item]
        guard let imageURL = URL(string: photo.regularImageURL) else { return }
        singleImageVC.imageURL = imageURL
        singleImageVC.transitioningDelegate = self
        singleImageVC.interactor = interactor
        singleImageVC.initialFrame.origin.x = initialFrame.origin.x + initialFrame.width / 2
        singleImageVC.initialFrame.origin.y = initialFrame.origin.y + initialFrame.height / 2
        
        singleImageVC.view.frame = self.view.bounds
        self.view.addSubview(singleImageVC.view)
        self.present(singleImageVC, animated: false, completion: nil)
        singleImageVC.didMove(toParent: self)
        
        singleImageVC.onDismiss = {
            collectionView.cellForItem(at: indexPath)?.contentView.alpha = 1
        }
    }
}

extension ImagesListViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imagesListCell = cell as? ImagesListCell else {
            return UICollectionViewCell()
        }
        imagesListCell.delegate = self
        
        configCell(for: imagesListCell, with: indexPath)
        return imagesListCell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = (collectionView.frame.width - 5) / 2
        var height = width * 1.44
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        5
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        guard let imageURL = URL(string: photo.smallImageURL) else { return }
        
        let offsetX: CGFloat = 0
        let offsetY: CGFloat = 0
        let cornerRadius: CGFloat = cell.cellImage.layer.cornerRadius
        
        let gradient = animationGradient.createGradient(
            width: cell.frame.width - offsetX * 2,
            height: cell.frame.height - offsetY * 2,
            offsetX: offsetX, offsetY: offsetY, cornerRadius: cornerRadius)
        cell.layer.addSublayer(gradient)
        cell.layer.cornerRadius = cell.cellImage.layer.cornerRadius
        
        cell.cellImage.kf.indicatorType = .activity
        cell.cellImage.kf.setImage(with: imageURL, placeholder: UIImage(named: "stubPlaceholder")) { _ in
            gradient.removeFromSuperlayer()
        }
        
        let date = dateFormatter.date(from: photo.createdAt ?? String())
        cell.dateLabel.text = dateFormatter.string(from: date ?? Date())
        
        cell.setIsLiked(isLiked: photo.isLiked)
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        UIBlockingProgressHUD.show()
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.item]
        
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked, indexPath: indexPath.item)
            .sink(receiveCompletion: { completion in
                DispatchQueue.main.async {
                    switch completion {
                        case .finished:
                            UIBlockingProgressHUD.dismiss()
                        case .failure(let error):
                            print(error)
                            UIBlockingProgressHUD.dismiss()
                    }
                }
            }, receiveValue: { [weak cell, weak self] photo in
                guard let cell = cell, let self = self else { return }
                DispatchQueue.main.async {
                    self.photos[indexPath.item].isLiked = photo.isLiked
                    cell.setIsLiked(isLiked: photo.isLiked)
                }
            }
            )
            .store(in: &cancellables)
    }
}
