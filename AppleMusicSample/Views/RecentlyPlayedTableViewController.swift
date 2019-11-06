/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`RecentlyPlayedTableViewController` is a `UITableViewController` subclass that lists all the recently played
             items for the current iTunes Store Account.
*/

import UIKit
import StoreKit

class RecentlyPlayedTableViewController: UITableViewController {
    
    // MARK: Properties
    
    /// The instance of `AuthorizationManager` used for querying and requesting authorization status.
    var authorizationManager: AuthorizationManager!
    
    /// The instance of `AppleMusicManager` which is used to make recently played item request calls to the Apple Music Web Services.
    var appleMusicManager: AppleMusicManager!
    
    /// The instance of `ImageCacheManager` that is used for downloading and caching album artwork images.
    let imageCacheManager = ImageCacheManager()
    
    /// The instance of `MusicPlayerManager` which is used for triggering the playback of a `MediaItem`.
    var musicPlayerManager: MusicPlayerManager!
    
    /// The instance of `MediaLibraryManager` which is used for adding items to the application's playlist.
    var mediaLibraryManager: MediaLibraryManager!
    
    /// The array of `MediaItem` objects that represents the list of search results.
    var mediaItems = [MediaItem]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: View Life-cycle Methods.
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if appleMusicManager.fetchDeveloperToken() == nil {
            
            let alertController = UIAlertController(title: "Error",
                                                    message: "No Developer Token was specified. See the README for more information.",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else if authorizationManager.userToken == "" {
            authorizationManager.requestUserToken()
            let alertController = UIAlertController(title: "Error",
                                                    message: "No User Token was specified. Request Authorization using the \"Authorization\" tab.",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            refreshData()
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MediaItemTableViewCell.identifier,
                                                       for: indexPath) as? MediaItemTableViewCell else {
                                                        return UITableViewCell()
        }
        
        let mediaItem = mediaItems[indexPath.row]
        
        cell.mediaItem = mediaItem
        cell.delegate = self
        
        // Image loading.
        let imageURL = mediaItem.artwork.imageURL(size: CGSize(width: 90, height: 90))
        
        if let image = imageCacheManager.cachedImage(url: imageURL) {
            // Cached: set immediately.
            
            cell.assetCoverArtImageView.image = image
            cell.assetCoverArtImageView.alpha = 1
        } else {
            // Not cached, so load then fade it in.
            cell.assetCoverArtImageView.alpha = 0
            
            imageCacheManager.fetchImage(url: imageURL, completion: { (image) in
                // Check the cell hasn't recycled while loading.
                
                if (cell.mediaItem?.identifier ?? "") == mediaItem.identifier {
                    cell.assetCoverArtImageView.image = image
                    UIView.animate(withDuration: 0.3) {
                        cell.assetCoverArtImageView.alpha = 1
                    }
                }
            })
        }
        
        let cloudServiceCapabilities = authorizationManager.cloudServiceCapabilities
        
        /*
         It is important to actually check if your application has the appropriate `SKCloudServiceCapability` options before enabling functionality
         related to playing back content from the Apple Music Catalog or adding items to the user's Cloud Music Library.
         */
        
        if cloudServiceCapabilities.contains(.addToCloudMusicLibrary) {
            cell.addToPlaylistButton.isEnabled = true
        } else {
            cell.addToPlaylistButton.isEnabled = false
        }
        
        if cloudServiceCapabilities.contains(.musicCatalogPlayback) {
            cell.playItemButton.isEnabled = true
        } else {
            cell.playItemButton.isEnabled = false
        }
        
        return cell
    }
    
    // MARK: Notification Observer Callback Methods.
    
    func handleMediaLibraryManagerLibraryDidUpdate() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func refreshData() {
        appleMusicManager.performAppleMusicGetRecentlyPlayed(userToken: authorizationManager.userToken) { [weak self] (mediaItems, error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    
                    // Your application should handle these errors appropriately depending on the kind of error.
                    
                    self?.mediaItems = []
                    
                    let alertController: UIAlertController
                    
                    guard let error = error as NSError?, let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? Error else {
                        
                        alertController = UIAlertController(title: "Error",
                                                            message: "Encountered unexpected error.",
                                                            preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                        
                        DispatchQueue.main.async {
                            self?.present(alertController, animated: true, completion: nil)
                        }
                        
                        return
                    }
                    
                    alertController = UIAlertController(title: "Error",
                                                        message: underlyingError.localizedDescription,
                                                        preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                    
                    DispatchQueue.main.async {
                        self?.present(alertController, animated: true, completion: nil)
                    }
                    
                    return
                }
                
                self?.mediaItems = mediaItems
            }
        }
    }
}

extension RecentlyPlayedTableViewController: MediaSearchTableViewCellDelegate {
    func mediaSearchTableViewCell(_ mediaSearchTableViewCell: MediaItemTableViewCell, addToPlaylist mediaItem: MediaItem) {
        mediaLibraryManager.addItem(with: mediaItem.identifier)
    }
    
    func mediaSearchTableViewCell(_ mediaSearchTableViewCell: MediaItemTableViewCell, playMediaItem mediaItem: MediaItem) {
        musicPlayerManager.beginPlayback(itemID: mediaItem.identifier)
    }
}
