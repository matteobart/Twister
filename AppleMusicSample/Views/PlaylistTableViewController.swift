/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`PlaylistTableViewController` is a `UITableViewController` subclass that list all the items in the playlist that was created by the app.
*/

import UIKit
import StoreKit

@objcMembers
class PlaylistTableViewController: UITableViewController {
    
    // MARK: Properties
    
    /// The instance of `AuthorizationManager` used for querying and requesting authorization status.
    var authorizationManager: AuthorizationManager!
    
    /// The instance of `MediaLibraryManager` that is used as a data source to display the contents of the application's playlist.
    var mediaLibraryManager: MediaLibraryManager!
    
    /// The instance of `MusicPlayerManager` that is used to trigger the playback of the application's playlist.
    var musicPlayerManager: MusicPlayerManager!
    
    // MARK: View Life-cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure self sizing cells.
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        
        // Add the notification observer needed to respond to events from the `MediaLibraryManager`.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMediaLibraryManagerLibraryDidUpdate),
                                               name: MediaLibraryManager.libraryDidUpdate, object: nil)
    }
    
    deinit {
        // Remove all notification observers.
        NotificationCenter.default.removeObserver(self,
                                          name: MediaLibraryManager.libraryDidUpdate,
                                          object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        /*
         It is important to actually check if your application has the appropriate `SKCloudServiceCapability` options before enabling functionality
         related to playing back content from the Apple Music Catalog or adding items to the user's Cloud Music Library.
         */
        
        let cloudServiceCapabilities = authorizationManager.cloudServiceCapabilities
        
        if cloudServiceCapabilities.contains(.musicCatalogPlayback) {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if mediaLibraryManager.mediaPlaylist != nil {
            return mediaLibraryManager.mediaPlaylist.items.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistTableViewCell.identifier,
                                                       for: indexPath) as? PlaylistTableViewCell else {
            return UITableViewCell()
        }

        let mediaItem = mediaLibraryManager.mediaPlaylist.items[indexPath.row]
        
        cell.mediaItemTitleLabel.text = mediaItem.title
        cell.mediaItemAlbumLabel.text = mediaItem.albumTitle
        cell.mediaItemArtistLabel.text = mediaItem.artist
        cell.assetCoverArtImageView.image = mediaItem.artwork?.image(at: CGSize(width: 80, height: 80))

        return cell
    }
    
    // MARK: Target-Action Methods
    
    @IBAction func handleUserDidPressPlayPlaylistButton(_ sender: Any) {
        let mediaPlaylist = mediaLibraryManager.mediaPlaylist
        
        musicPlayerManager.beginPlayback(itemCollection: mediaPlaylist!)
    }
    
    // MARK: Notification Observer Callback Methods

    func handleMediaLibraryManagerLibraryDidUpdate() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
