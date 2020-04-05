//
//  SettingsTableViewController.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/19/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var authAppleMusicLabel: UILabel!
    @IBOutlet weak var authSpotifyLabel: UILabel!
    
    func updateLabels() {
        if authorizationManager.isAuthenticated() {
            authAppleMusicLabel.text = "Apple Music is Authorized"
        } else if authorizationManager.isDenied() {
            authAppleMusicLabel.text = "Apple Music is Denied"
        } else {
            authAppleMusicLabel.text = "Authorize Apple Music"
        }
        authSpotifyLabel.text = spotifyManager.isAuthorized() ? "Deauthorize Spotify" : "Authorize Spotify"
    }
        
        
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            if authorizationManager.isAuthenticated() { // apple music
                let alert = UIAlertController(title: "Apple Music is Authorized", message: "There is nothing to do!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            } else if authorizationManager.isDenied() {
                let alert = UIAlertController(title: "Apple Music has been denied", message: "To give access to Twister. Please delete the app and redownload it.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            } else { // lets auth
                let alert = UIAlertController(title: "Twister will Request Access", message: "For Twister to work, we must request access to your music library. The following prompt will ask you to give access to Twister.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Let's do it!", style: .default, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
                authorizationManager.requestCloudServiceAuthorization()
                authorizationManager.requestMediaLibraryAuthorization()
            }
            updateLabels()
        } else if indexPath.item == 1 { // spotify
            if spotifyManager.isAuthorized() {
                spotifyManager.deauthorize()
            } else {
                spotifyManager.authorize()
            }
            updateLabels()
        } else if indexPath.item == 2 { //FAQ
            let items = [FAQItem(question: "Do you need an account for Apple Music and Spotify?",
                                 answer: "Yes! You will need an account for both services. However you do not need a premium Spotify account to transfer playlists to or from Spotify."),
                         FAQItem(question: "Why does the process take so long?",
                                answer: "iTunes currently limits you to search for 20 songs per minute. This means that if your playlist contains 300 songs this will take 15 minutes to convert to Apple Music. Playlists to Spotify should be near instantaneous."),
                         FAQItem(question: "Any future streaming services?",
                                 answer: "Possibly! If you have any recommendations feel free to reach out to us by email at matteodevapps@gmail.com"),
                         FAQItem(question: "I found a bug! What should I do?",
                                 answer: "Oh no! Be sure to bring him outside and don't squash him. Let us know by emailing matteodevapps@gmail.com"),
                         FAQItem(question: "This is a cool app! Can I help out?",
                                 answer: "If you're a developer or graphic designer or think you can be valuable feel free to check out the code for this app available at www.github.com/matteobart/Twister")
                        ]
            let faqView = FAQView(frame: view.frame, title: "FAQ", items: items)
            view.addSubview(faqView)
        }
    }
    // MARK: - Table view data source

    //override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
    //    return 0
    //}

    //override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
    //    return 0
    //}

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
