import UIKit

class ImagesListViewController: UIViewController {
    private var photosName = [String]()
    private let ShowSingleImageSegueIdentifier = "ShowSingleImage"
    private let imagesListService = ImagesListService.shared
    private let storageToken = OAuth2TokenStorage()
    private var imagesListServiceObserver: NSObjectProtocol?
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    @IBOutlet private var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        photosName = Array(0...20).map{ "\($0)" }
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.DidChangeNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let self = self else { return }
//                self.updatePhoto()
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowSingleImageSegueIdentifier {
            let viewController = segue.destination as! SingleImageViewController
            let indexPath = sender as! IndexPath
            let image = UIImage(named: photosName[indexPath.row])
            viewController.image = image
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
        return photosName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
    
}

extension ImagesListViewController {
    
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        guard let image = UIImage(named: photosName[indexPath.row]) else { return }
        cell.cellImage.image = image
        cell.dateLabel.text = dateFormatter.string(from: NSDate() as Date)
        cell.likeButton.imageView?.image = indexPath.row % 2 == 1 ? UIImage(named: "Active") : UIImage(named: "No Active")
    }
}

extension ImagesListViewController {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard storageToken.token != nil else { return }
        UIBlockingProgressHUD.show()
        if indexPath.row + 1 == imagesListService.photos.count {
            imagesListService.fetchPhotosNextPage(storageToken.token!) { result in
                DispatchQueue.main.async { [self] in
                    do {
                        let photos = try result.get()
//                        tableView.cellForRow(at: indexPath)?.imageView?.image = photos[indexPath.row].largeImageURL
//                        storageToken.token = data
//                        self.fetchProfile(token: storageToken.token!)
                        UIBlockingProgressHUD.dismiss()
                    } catch let error {
                        print("Error: ", error)
                        UIBlockingProgressHUD.dismiss()
                    }
                }
            }
        }
    }
}
