//
//  SettingsTableViewController.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/19/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import MessageUI

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var authAppleMusicLabel: UILabel!
    @IBOutlet weak var authSpotifyLabel: UILabel!
    @IBOutlet weak var appleMusicImageView: UIImageView!
    @IBOutlet weak var spotifyImageView: UIImageView!
    
    
    func updateLabels() {
        if authorizationManager.isAuthenticated() {
            authAppleMusicLabel.text = "Apple Music is Authorized"
            appleMusicImageView.image = UIImage(systemName: "checkmark.square.fill")
            
        } else if authorizationManager.isDenied() {
            authAppleMusicLabel.text = "Apple Music is Denied"
            appleMusicImageView.image = UIImage(systemName: "exclamationmark.square.fill")
            
        } else {
            authAppleMusicLabel.text = "Authorize Apple Music"
            appleMusicImageView.image = UIImage(systemName: "questionmark.square.fill")
        }
        authSpotifyLabel.text = spotifyManager.isAuthorized() ? "Deauthorize Spotify" : "Authorize Spotify"
        spotifyImageView.image = spotifyManager.isAuthorized() ? UIImage(systemName: "checkmark.square.fill") : UIImage(systemName: "questionmark.square.fill")
    }
        
        
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        NotificationCenter.default.addObserver(self, selector: #selector(cloudServiceChanged), name: AuthorizationManager.cloudServiceDidUpdateNotification, object: nil)
        self.clearsSelectionOnViewWillAppear = true
    }
    
    @objc func cloudServiceChanged() {
        DispatchQueue.main.async {
            self.updateLabels()
            self.unselectSelected()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.item == 0 {
            if authorizationManager.isAuthenticated() { // apple music
                let alert = UIAlertController(title: "Apple Music is Authorized", message: "There is nothing to do!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            } else if authorizationManager.isDenied() {
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
            } else { // lets auth
                let alert = UIAlertController(title: "Twister will Request Access", message: "For Twister to work, we must request access to your music library. The following prompt will ask you to give access to Twister.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Let's do it!", style: .default) { (_) in
                    authorizationManager.requestMediaLibraryAuthorization()
                    authorizationManager.requestCloudServiceAuthorization()
                }
                alert.addAction(okAction)
                present(alert, animated: true) {
                }
            }
            updateLabels()
            unselectSelected()
        } else if indexPath.section == 0 && indexPath.item == 1 { // spotify
            if spotifyManager.isAuthorized() {
                let alert = UIAlertController(title: "Deauthorize Spotify", message: "Are you sure you would like to deauthorize Spotify?", preferredStyle: .alert)
                let openAction = UIAlertAction(title: "Deauthorize", style: .default) { (_) in
                    spotifyManager.deauthorize()
                    self.updateLabels()
                }
                let closeAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                alert.addAction(closeAction)
                alert.addAction(openAction)
                present(alert, animated: true, completion: nil)
                unselectSelected()
            } else {
                spotifyManager.authorize()
            }
            updateLabels()
        } else if indexPath.section == 1 && indexPath.item == 0 { //FAQ
            var range = NSRange()
            let an3 = NSMutableAttributedString(string: "Possibly! If you have any recommendations feel free to reach out to us by email at matteodevapps@gmail.com")
            range = NSString(string: an3.string).range(of: "matteodevapps@gmail.com")
            an3.addAttribute(.link, value: "mailto:matteodevapps@gmail.com", range: range)
            let an4 = NSMutableAttributedString(string: "Oh no! Be sure to bring him outside and don't squash him. Let us know by emailing matteodevapps@gmail.com")
            range = NSString(string: an4.string).range(of: "matteodevapps@gmail.com")
            an4.addAttribute(.link, value: "mailto:matteodevapps@gmail.com", range: range)
            let an5 = NSMutableAttributedString(string: "If you're a developer or graphic designer or think you can be valuable feel free to check out the code for this app available at www.github.com/matteobart/Twister")
            range = NSString(string: an5.string).range(of: "www.github.com/matteobart/Twister")
            an5.addAttribute(.link, value: "https://www.github.com/matteobart/Twister", range: range)
            let items = [FAQItem(question: "Do you need an account for Apple Music and Spotify?",
                                 answer: "Yes! You will need an account for both services. However you do not need a premium Spotify account to transfer playlists to or from Spotify."),
                         FAQItem(question: "Why does the process take so long?",
                                answer: "iTunes currently limits you to search for 20 songs per minute. This means that if your playlist contains 300 songs this will take 15 minutes to convert to Apple Music. Playlists to Spotify should be near instantaneous."),
                         FAQItem(question: "Any future streaming services?", partiallyAttributed: an3),
                         FAQItem(question: "I found a bug! What should I do?", partiallyAttributed: an4),
                         FAQItem(question: "This is a cool app! Can I help out?", partiallyAttributed: an5)
                        ]
            let faqView = FAQView(frame: view.frame, title: "", items: items)
            //view.addSubview(faqView)
            let controller = UIViewController()
            controller.view = faqView
            controller.title = "FAQ"
            controller.modalPresentationStyle = .fullScreen
            show(controller, sender: nil)
        } else if indexPath.section == 1 && indexPath.item == 1 { //contact us
            sendEmail()
        }
    }
    
    func unselectSelected() {
        if tableView?.indexPathForSelectedRow != nil {
            tableView.deselectRow(at: tableView!.indexPathForSelectedRow!, animated: true)
        }
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["matteodevapps@gmail.com"])
            //mail.setMessageBody("<p>You're so awesome!</p>", isHTML: true)

            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        unselectSelected()
        controller.dismiss(animated: true)
    }
}
