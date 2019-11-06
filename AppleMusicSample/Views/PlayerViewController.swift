/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`PlayerViewController` is a `UIViewController` provides basic metadata about the currently playing `MPMediaItem`
             as well as playback controls.
*/

import UIKit
import MediaPlayer

@objcMembers
class PlayerViewController: UIViewController {
    
    /// The `UIImageView` for displaying the artwork of the currently playing `MPMediaItem`.
    @IBOutlet weak var currentItemArtworkImageView: UIImageView!
    
    /// The 'UILabel` for displaying the title of the currently playing `MPMediaItem`.
    @IBOutlet weak var currentItemTitleLabel: UILabel!
    
    /// The 'UILabel` for displaying the album title of the currently playing `MPMediaItem`.
    @IBOutlet weak var currentItemAlbumLabel: UILabel!
    
    /// The 'UILabel` for displaying the artist of the currently playing `MPMediaItem`.
    @IBOutlet weak var currentItemArtistLabel: UILabel!
    
    /**
     The `UIButton` that can be used to either return back to the beginning of the currently playing `MPMediaItem` or to switch playback to the
     previous `MPMediaItem` in the list if any.  See `handleUserDidPressBackwardButton(_:)` for how this is determined.
     */
    @IBOutlet weak var skipToPreviousItemButton: UIButton!
    
    /// The `UIButton` that can be used to play or pause playback of the currently playing `MPMediaItem`.
    @IBOutlet weak var playPauseButton: UIButton!
    
    /// The `UIButton` that can be used to switch playback to the next `MPMediaItem` in the list if any.
    @IBOutlet weak var skipToNextItemButton: UIButton!
    
    /// The instance of `MusicPlayerManager` used by the `PlayerViewController` to control `MPMediaItem` playback.
    var musicPlayerManager: MusicPlayerManager!
    
    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the notification observer needed to respond to events from the `MusicPlayerManager`.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMusicPlayerManagerDidUpdateState),
                                               name: MusicPlayerManager.didUpdateState,
                                               object: nil)
        
        updatePlaybackControls()
        updateCurrentItemMetadata()
    }
    
    deinit {
        // Remove all notification observers.
        NotificationCenter.default.removeObserver(self,
                                                  name: MusicPlayerManager.didUpdateState,
                                                  object: nil)
    }
    
    // MARK: Target-Action Methods
    
    @IBAction func handleUserDidPressBackwardButton(_ sender: Any) {
        musicPlayerManager.skipBackToBeginningOrPreviousItem()
    }
    
    @IBAction func handleUserDidPressPlayPauseButton(_ sender: Any) {
        musicPlayerManager.togglePlayPause()
    }
    
    @IBAction func handleUserDidPressForwardButton(_ sender: Any) {
        musicPlayerManager.skipToNextItem()
    }
    
    // MARK: UI Update Methods
    
    func updatePlaybackControls() {
        let playbackState = musicPlayerManager.musicPlayerController.playbackState
        
        switch playbackState {
        case .interrupted, .paused, .stopped:
            playPauseButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        case .playing:
            playPauseButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        default:
            break
        }
        
        if playbackState == .stopped {
            skipToPreviousItemButton.isEnabled = false
            playPauseButton.isEnabled = false
            skipToNextItemButton.isEnabled = false
        } else {
            skipToPreviousItemButton.isEnabled = true
            playPauseButton.isEnabled = true
            skipToNextItemButton.isEnabled = true
        }
        
        updateCurrentItemMetadata()
    }
    
    func updateCurrentItemMetadata() {
        
        if let nowPlayingItem = musicPlayerManager.musicPlayerController.nowPlayingItem {
            
            currentItemArtworkImageView.image = nowPlayingItem.artwork?.image(at: currentItemArtworkImageView.frame.size)
            currentItemTitleLabel.text = nowPlayingItem.title
            currentItemAlbumLabel.text = nowPlayingItem.albumTitle
            currentItemArtistLabel.text = nowPlayingItem.artist
        } else {
            currentItemArtworkImageView.image = nil
            currentItemTitleLabel.text = "No Item Playing"
            currentItemAlbumLabel.text = " "
            currentItemArtistLabel.text = " "
        }
    }
    
    // MARK: Notification Observing Methods
    
    func handleMusicPlayerManagerDidUpdateState() {
        DispatchQueue.main.async {
            self.updatePlaybackControls()
            self.updateCurrentItemMetadata()
        }
    }
}
