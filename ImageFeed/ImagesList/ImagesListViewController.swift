import UIKit
import Kingfisher

protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol { get set }
    func updateTableViewAnimated()
}

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    private let ShowSingleImageSegueIdentifier = "ShowSingleImage"
    private let imagesListService = ImagesListService.shared
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowSingleImageSegueIdentifier {
            let viewController = segue.destination as! SingleImageViewController
            let indexPath = sender as! IndexPath
            let photo = photos[indexPath.row]
            guard let imageURL = URL(string: photo.largeImageURL) else { return }
            viewController.imageURL = imageURL
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}


extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: ShowSingleImageSegueIdentifier, sender: indexPath)
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
        guard let imageURL = URL(string: photo.thumbImageURL) else { return }
        
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
        
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked, indexPath: indexPath.row) { [weak cell, weak self] response in
            guard let cell = cell,
                  let self = self
            else { return }
            
            DispatchQueue.main.async {
                switch response {
                case .success(let photo):
                    self.photos[indexPath.row].isLiked = photo.isLiked
                    cell.setIsLiked(isLiked: photo.isLiked)
                    UIBlockingProgressHUD.dismiss()
                case .failure(let error):
                    print(error)
                    UIBlockingProgressHUD.dismiss()
                }
            }
        }
    }
}
