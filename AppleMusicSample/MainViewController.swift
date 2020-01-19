//
//  MainViewController.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/18/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import SpotifyKit

class MainViewController: UIViewController {

    @IBOutlet weak var toSegControl: UISegmentedControl!
    @IBOutlet weak var fromSegControl: UISegmentedControl!
    @IBOutlet weak var playlistNameTextField: UITextField!
    @IBOutlet weak var availablePlaylistsTableView: UITableView!
    
    
    let numberOfServices = 2
    var allPlaylists: [[(String, String)]] = [] //a N dimensional array (where N is the number of services eg. spotify)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playlistNameTextField.delegate = self
        availablePlaylistsTableView.delegate = self
        availablePlaylistsTableView.dataSource = self
        spotifyManager.authorize()
        
        for _ in 0..<numberOfServices {
            allPlaylists.append([])
        }
        
        spotifyManager.library(SpotifyPlaylist.self) { (libraryItems) in
            for item in libraryItems {
                print(item)
                self.allPlaylists[1].append((item.name, item.id))
            }
            self.availablePlaylistsTableView.reloadData()
        }
        
    }
    
    @IBAction func segContolChanged(_ sender: UISegmentedControl) {
        let changedSegControl = sender
        let otherSegContol = (sender.tag != toSegControl.tag ? toSegControl : fromSegControl)!
        if changedSegControl.selectedSegmentIndex == otherSegContol.selectedSegmentIndex {
            otherSegContol.selectedSegmentIndex = (otherSegContol.selectedSegmentIndex + 1) % otherSegContol.numberOfSegments
        }
        availablePlaylistsTableView.reloadData()
    }
    @IBAction func twistButtonPressed(_ sender: UIButton) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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

extension UIViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allPlaylists[1].count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistTableViewCell.identifier,
                                                       for: indexPath) as? PlaylistTableViewCell else {
            return UITableViewCell()
        }
        //cell.creatorNameLabel.text = allPlaylists[1][indexPath.item].1
        cell.playlistNameLabel.text = allPlaylists[1][indexPath.item].0
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath) as! PlaylistTableViewCell
        playlistNameTextField.text = selectedCell.playlistNameLabel.text
    }
    
    
    
}
