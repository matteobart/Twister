//
//  MainViewController.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/18/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import SpotifyKit
import MediaPlayer

class MainViewController: UIViewController {

    @IBOutlet weak var toSegControl: UISegmentedControl!
    @IBOutlet weak var fromSegControl: UISegmentedControl!
    @IBOutlet weak var playlistNameTextField: UITextField!
    @IBOutlet weak var availablePlaylistsTableView: UITableView!
    @IBOutlet weak var twistButton: UIButton!

    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!

    
    var authController: AuthorizationViewController? // ideally this will be able to be removed
    
    //let numberOfServices = 2
    var allPlaylists: [[(String, String)]] = [] //a 2D array (where numCols is the number of services eg. spotify)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
               selector: #selector(self.keyboardNotification(notification:)),
               name: UIResponder.keyboardWillChangeFrameNotification,
               object: nil)
        
        playlistNameTextField.delegate = self
        availablePlaylistsTableView.delegate = self
        availablePlaylistsTableView.dataSource = self
        
        twistButton.layer.cornerRadius = 10
        twistButton.layer.borderWidth = 1
        
        if !spotifyManager.isAuthorized() || !authorizationManager.isAuthenticated() {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "authVC")
            nextViewController.modalPresentationStyle = .fullScreen
            authController = nextViewController as? AuthorizationViewController
            self.present(nextViewController, animated:true, completion:nil)
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        twistButton.backgroundColor = .gray
        
        allPlaylists = []
        for _ in StreamingService.allCases {
            allPlaylists.append([])
        }
        
        //add spotify playlists
        spotifyManager.library(SpotifyPlaylist.self) { (libraryItems) in
            for item in libraryItems {
                self.allPlaylists[1].append((item.name, item.id ?? ""))
            }
            self.availablePlaylistsTableView.reloadData()
        }
        
        //add apple music playlists
        if authorizationManager.isAuthenticated() {
            let myPlaylistQuery = MPMediaQuery.playlists()
            guard let playlists = myPlaylistQuery.collections else { return }
            for playlist in playlists {
                let playlistName = playlist.value(forProperty: MPMediaPlaylistPropertyName) as! String
                let playlistUUID = String(describing: playlist.value(forProperty: MPMediaPlaylistPropertyPersistentID)!)
                self.allPlaylists[0].append((playlistName, playlistUUID))
            }
            
        }
    }
    
    
    
    @IBAction func segContolChanged(_ sender: UISegmentedControl) {
        let changedSegControl = sender
        let otherSegContol = (sender.tag != toSegControl.tag ? toSegControl : fromSegControl)!
        if changedSegControl.selectedSegmentIndex == otherSegContol.selectedSegmentIndex {
            otherSegContol.selectedSegmentIndex = (otherSegContol.selectedSegmentIndex + 1) % otherSegContol.numberOfSegments
            playlistNameTextField.text = ""
            self.twistButton.backgroundColor = .gray
        }
        availablePlaylistsTableView.reloadData()
        if sender == fromSegControl { //clean interface
            playlistNameTextField.text = ""
            self.twistButton.backgroundColor = .gray
        }
    }
    @IBAction func twistButtonPressed(_ sender: UIButton) {
        guard let selectedRow = availablePlaylistsTableView.indexPathForSelectedRow else {
            //throw a pop up
            let alert = UIAlertController(title: "Nothing to Twist", message: "Please choose a playlist from the above list to Twist", preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
            alert.addAction(closeAction)
            present(alert, animated: true, completion: nil)
            return
        }
        let playlistId = (availablePlaylistsTableView.cellForRow(at: selectedRow) as! PlaylistTableViewCell).playlistId
        let playlistName = (availablePlaylistsTableView.cellForRow(at: selectedRow) as! PlaylistTableViewCell).playlistNameLabel.text ?? ""
        let fromService = fromSegControl.selectedSegmentIndex == 0 ? StreamingService.appleMusic : StreamingService.spotify
        let toService = toSegControl.selectedSegmentIndex == 0 ? StreamingService.appleMusic : StreamingService.spotify
        let newPlaylistName = playlistNameTextField.text ?? "New Playlist"

        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "resultsVC") as! ResultsViewController

        nextViewController.fromService = fromService
        nextViewController.toService = toService
        nextViewController.playlistName = playlistName
        nextViewController.playlistId = playlistId
        nextViewController.newPlaylistName = newPlaylistName
        nextViewController.title = "Finding Songs"
        self.show(nextViewController, sender: nil)
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

extension MainViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    //not required to be here, but related to text field
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if endFrameY >= UIScreen.main.bounds.size.height {
                self.bottomLayoutConstraint?.constant = 0.0
            } else {
                self.bottomLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            }
            UIView.animate(withDuration: duration,
                                       delay: TimeInterval(0),
                                       options: animationCurve,
                                       animations: { self.view.layoutIfNeeded() },
                                       completion: nil)
        }
    }
    
    //not required to be here, but related to text field
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allPlaylists[fromSegControl.selectedSegmentIndex].count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistTableViewCell.identifier,
                                                       for: indexPath) as? PlaylistTableViewCell else {
            return UITableViewCell()
        }
        cell.playlistNameLabel.text = allPlaylists[fromSegControl.selectedSegmentIndex][indexPath.item].0
        cell.playlistId = allPlaylists[fromSegControl.selectedSegmentIndex][indexPath.item].1
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath) as! PlaylistTableViewCell
        playlistNameTextField.text = selectedCell.playlistNameLabel.text
        self.twistButton.backgroundColor = appTint
        self.twistButton.isEnabled = true
        self.twistButton.isUserInteractionEnabled = true
    }
    
    
    
    
}
