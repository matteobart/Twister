/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`PlaylistTableViewCell` is a `UITableViewCell` subclass that represents an `MPMediaItem` in the
             `MPMediaPlaylist` created by the `MediaLibraryManager`.
*/

import UIKit

class PlaylistTableViewCell: UITableViewCell {
    
    // MARK: Types
    
    static let identifier = "PlaylistTableViewCell"
    
    // MARK: Properties
    
    /// The `UIImageView` for displaying the artwork of the currently playing `MPMediaItem`.
    @IBOutlet weak var assetCoverArtImageView: UIImageView!
    
    /// The 'UILabel` for displaying the title of `MPMediaItem`.
    @IBOutlet weak var mediaItemTitleLabel: UILabel!
    
    /// The 'UILabel` for displaying the album of `MPMediaItem`.
    @IBOutlet weak var mediaItemAlbumLabel: UILabel!
    
    /// The 'UILabel` for displaying the artist of `MPMediaItem`.
    @IBOutlet weak var mediaItemArtistLabel: UILabel!
}
