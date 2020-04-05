//
//  AuthorizationViewController.swift
//  Twister
//
//  Created by Matteo Bart on 4/5/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class AuthorizationViewController: UIViewController {

    @IBOutlet weak var appleMusicStateImageView: UIImageView!
    @IBOutlet weak var spotifyStateImageView: UIImageView!
    
    @IBOutlet weak var authAppleMusicButton: UIButton!
    @IBOutlet weak var authSpotifyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViews()
    }
    
    
    func updateViews() {
        if authorizationManager.isAuthenticated() {
            spotifyStateImageView.image = UIImage(systemName: "checkmark.square.fill")
            authAppleMusicButton.setTitle("Apple Music is Authorized", for: .normal)
            authAppleMusicButton.isEnabled = false
            authAppleMusicButton.isUserInteractionEnabled = false
        } else if authorizationManager.isDenied() {
            appleMusicStateImageView.image = UIImage(systemName: "exclamationmark.square.fill")
            authAppleMusicButton.setTitle("Apple Music Access is Denied", for: .normal)
            authAppleMusicButton.isEnabled = true
            authAppleMusicButton.isUserInteractionEnabled = true
        } else {
            appleMusicStateImageView.image = UIImage(systemName: "questionmark.square.fill")
            authAppleMusicButton.isEnabled = true
            authAppleMusicButton.isUserInteractionEnabled = true
        }
        
        if spotifyManager.isAuthorized() {
            spotifyStateImageView.image = UIImage(systemName: "checkmark.square.fill")
            authSpotifyButton.setTitle("Spotify is Authorized", for: .normal)
            authSpotifyButton.isEnabled = false
            authSpotifyButton.isUserInteractionEnabled = false
        } else {
            spotifyStateImageView.image = UIImage(systemName: "questionmark.square.fill")
            authSpotifyButton.isEnabled = true
            authSpotifyButton.isUserInteractionEnabled = true
        }
        
    }
    
    func checkIfDismiss() {
        if authorizationManager.isAuthenticated() && spotifyManager.isAuthorized() {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func authAppleMusicPressed(_ sender: UIButton) {
        if authorizationManager.isDenied() {
            let alert = UIAlertController(title: "Apple Music has been denied", message: "To give access to Twister. Please delete the app and redownload it.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Twister will Request Access", message: "For Twister to work, we must request access to your music library. The following prompt will ask you to give access to Twister.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Let's do it!", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true) {
                authorizationManager.requestMediaLibraryAuthorization()
                authorizationManager.requestCloudServiceAuthorization()
                self.updateViews()
            }
        }
            
        updateViews()
        checkIfDismiss()
    }
    
    @IBAction func authSpotifyPressed(_ sender: UIButton) {
        spotifyManager.authorize()
        
        updateViews()
        checkIfDismiss()
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
