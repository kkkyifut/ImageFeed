import UIKit
import Kingfisher
import Combine

protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol { get set }
    func updateTableViewAnimated()
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
    
    @IBOutlet private var tableView: UITableView!
    
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
    
    internal func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        if oldCount != newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                tableView.insertRows(at: indexPaths, with: .bottom)
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


extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let singleImageVC = storyboardInstance.instantiateViewController(identifier: "SingleImageViewController") as! SingleImageViewController
        singleImageVC.hidesBottomBarWhenPushed = true
        singleImageVC.modalPresentationStyle = .overFullScreen

        let rectOfCellInTableView = tableView.rectForRow(at: indexPath)
        tableView.cellForRow(at: indexPath)?.contentView.alpha = 0

        let initialFrame = tableView.convert(rectOfCellInTableView, to: view)
        let photo = photos[indexPath.row]
        guard let imageURL = URL(string: photo.regularImageURL) else { return }
        singleImageVC.imageURL = imageURL
        singleImageVC.transitioningDelegate = self
        singleImageVC.interactor = interactor
        singleImageVC.initialCenter = initialFrame
        singleImageVC.initialCenter.origin.y = initialFrame.origin.y + initialFrame.height / 2
                
        singleImageVC.view.frame = self.view.bounds
        self.view.addSubview(singleImageVC.view)
        self.present(singleImageVC, animated: false, completion: nil)
        singleImageVC.didMove(toParent: self)
        
        singleImageVC.onDismiss = {
            tableView.cellForRow(at: indexPath)?.contentView.alpha = 1
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imagesListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        imagesListCell.delegate = self
        
        configCell(for: imagesListCell, with: indexPath)
        return imagesListCell
    }
}

extension ImagesListViewController {
    
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        guard let imageURL = URL(string: photo.smallImageURL) else { return }
        
        let offsetX: CGFloat = 20
        let offsetY: CGFloat = 3
        let cornerRadius: CGFloat = cell.cellImage.layer.cornerRadius
        
        let gradient = animationGradient.createGradient(
            width: cell.frame.width - offsetX * 2,
            height: cell.frame.height - offsetY * 2,
            offsetX: offsetX, offsetY: offsetY, cornerRadius: cornerRadius)
        cell.layer.addSublayer(gradient)
        
        cell.cellImage.kf.indicatorType = .activity
        cell.cellImage.kf.setImage(with: imageURL, placeholder: UIImage(named: "stubPlaceholder")) { _ in
            gradient.removeFromSuperlayer()
        }
        
        let date = dateFormatter.date(from: photo.createdAt ?? String())
        cell.dateLabel.text = dateFormatter.string(from: date ?? Date())
        
        cell.setIsLiked(isLiked: photo.isLiked)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = photos[indexPath.row]
        let imageSize = CGSize(width: cell.width, height: cell.height)
        let aspectRatio = imageSize.width / imageSize.height
        return tableView.frame.width / aspectRatio
    }
}

extension ImagesListViewController {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        UIBlockingProgressHUD.show()
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked, indexPath: indexPath.row)
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
                    self.photos[indexPath.row].isLiked = photo.isLiked
                    cell.setIsLiked(isLiked: photo.isLiked)
                }
            }
            )
            .store(in: &cancellables)
    }
}
