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
        
        authSpotifyButton.layer.cornerRadius = 10
        authSpotifyButton.layer.borderWidth = 1
        authAppleMusicButton.layer.cornerRadius = 10
        authAppleMusicButton.layer.borderWidth = 1
        
        NotificationCenter.default.addObserver(self, selector: #selector(cloudServiceChanged), name: AuthorizationManager.cloudServiceDidUpdateNotification, object: nil)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViews()
    }
    
    @objc func cloudServiceChanged(){
        DispatchQueue.main.async {
            self.updateViews()
            self.checkIfDismiss()
        }
    }
    
    func updateViews() {
        if authorizationManager.isAuthenticated() {
            appleMusicStateImageView.image = UIImage(systemName: "checkmark.square.fill")
            authAppleMusicButton.setTitle("Apple Music is Authorized", for: .normal)
            authAppleMusicButton.backgroundColor = .gray
            authAppleMusicButton.setTitleColor(.white, for: .normal)
            authAppleMusicButton.isEnabled = false
            authAppleMusicButton.isUserInteractionEnabled = false
        } else if authorizationManager.isDenied() {
            appleMusicStateImageView.image = UIImage(systemName: "exclamationmark.square.fill")
            appleMusicStateImageView.tintColor = .orange
            authAppleMusicButton.setTitle("Apple Music is Denied", for: .normal)
            authAppleMusicButton.backgroundColor = .orange
            authAppleMusicButton.setTitleColor(.white, for: .normal)
            authAppleMusicButton.isEnabled = true
            authAppleMusicButton.isUserInteractionEnabled = true
        } else {
            appleMusicStateImageView.image = UIImage(systemName: "questionmark.square.fill")
            appleMusicStateImageView.tintColor = .yellow
            authAppleMusicButton.backgroundColor = .yellow
            authAppleMusicButton.setTitleColor(.black, for: .normal)
            authAppleMusicButton.isEnabled = true
            authAppleMusicButton.isUserInteractionEnabled = true
        }
        
        if spotifyManager.isAuthorized() {
            spotifyStateImageView.image = UIImage(systemName: "checkmark.square.fill")
            authSpotifyButton.setTitle("Spotify is Authorized", for: .normal)
            authSpotifyButton.backgroundColor = .gray
            authSpotifyButton.setTitleColor(.white, for: .normal)
            authSpotifyButton.isEnabled = false
            authSpotifyButton.isUserInteractionEnabled = false
        } else {
            spotifyStateImageView.image = UIImage(systemName: "questionmark.square.fill")
            spotifyStateImageView.tintColor = .yellow
            authSpotifyButton.backgroundColor = .yellow
            authSpotifyButton.setTitleColor(.black, for: .normal)
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
            let alert = UIAlertController(title: "Apple Music has been denied", message: "To give access to Twister: go into the Settings app -> open Twister's settings -> find 'Allow Twister to Access' -> make sure 'Media & Apple Music' is turned on", preferredStyle: .alert)
            let openAction = UIAlertAction(title: "Open Settings", style: .default) { (_) in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }
            let closeAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
            alert.addAction(closeAction)
            alert.addAction(openAction)
            present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Twister will Request Access", message: "For Twister to work, we must request access to your music library. The following prompt will ask you to give access to Twister.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Let's do it!", style: .default) { (_) in
                authorizationManager.requestMediaLibraryAuthorization()
                authorizationManager.requestCloudServiceAuthorization()
            }
            alert.addAction(okAction)
            present(alert, animated: true) {
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
