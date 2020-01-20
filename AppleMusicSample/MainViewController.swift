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

enum StreamingService: String, CaseIterable {
    case spotify
    case appleMusic
}

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
        
        for _ in StreamingService.allCases {
            allPlaylists.append([])
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //add spotify playlists
        spotifyManager.library(SpotifyPlaylist.self) { (libraryItems) in
            for item in libraryItems {
                self.allPlaylists[1].append((item.name, item.id))
            }
            self.availablePlaylistsTableView.reloadData()
        }
        
        //add apple music playlists
        let myPlaylistQuery = MPMediaQuery.playlists()
        let playlists = myPlaylistQuery.collections
        for playlist in playlists! {
            let playlistName = playlist.value(forProperty: MPMediaPlaylistPropertyName) as! String
            let playlistUUID = String(describing: playlist.value(forProperty: MPMediaPlaylistPropertyPersistentID)!)
            self.allPlaylists[0].append((playlistName, playlistUUID))
            /*let songs = playlist.items
            for song in songs {
                let songTitle = song.title!
                let artist = song.artist!
                print("\t\t", songTitle, "->", artist)
            }*/
        }
    }
    
    
    
    @IBAction func segContolChanged(_ sender: UISegmentedControl) {
        let changedSegControl = sender
        let otherSegContol = (sender.tag != toSegControl.tag ? toSegControl : fromSegControl)!
        if changedSegControl.selectedSegmentIndex == otherSegContol.selectedSegmentIndex {
            otherSegContol.selectedSegmentIndex = (otherSegContol.selectedSegmentIndex + 1) % otherSegContol.numberOfSegments
            playlistNameTextField.text = ""
        }
        availablePlaylistsTableView.reloadData()
        if sender == fromSegControl { //clean interface
            playlistNameTextField.text = ""
        }
    }
    @IBAction func twistButtonPressed(_ sender: UIButton) {
        guard let selectedRow = availablePlaylistsTableView.indexPathForSelectedRow else {
            //throw a pop up
            return
        }
        let playlistId = (availablePlaylistsTableView.cellForRow(at: selectedRow) as! PlaylistTableViewCell).playlistId
        let playlistName = (availablePlaylistsTableView.cellForRow(at: selectedRow) as! PlaylistTableViewCell).playlistNameLabel.text ?? ""
        let fromService = fromSegControl.selectedSegmentIndex == 0 ? StreamingService.appleMusic : StreamingService.spotify
        let toService = toSegControl.selectedSegmentIndex == 0 ? StreamingService.appleMusic : StreamingService.spotify
        
        print(playlistId, fromService)
        
        var toAdd: [(String, String)] = [] //(trackName, artistName)
        if fromService == .spotify {
            spotifyManager.get(SpotifyPlaylist.self, id: playlistId) { (searchItem) in
                guard let _ = searchItem.collectionTracks else {return}
                for item in searchItem.collectionTracks! {
                    print(item.name, "->" ,item.artist.name)
                    toAdd.append((item.name, item.artist.name))
                }
            }
        } else if fromService == .appleMusic {
            let myPlaylistQuery = MPMediaQuery.playlists()
            myPlaylistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: UInt64(playlistId), forProperty: MPMediaPlaylistPropertyPersistentID))
            let fromPlaylist = (myPlaylistQuery.collections)![0]
            for item in fromPlaylist.items {
                print(item.title ?? "", "->", item.artist ?? "")
                toAdd.append((item.title ?? "" , item.artist ?? "" ))
            }
            
        }
        
        if toService == .appleMusic {
            let playlistUUID = UUID()
            
            // Create an instance of `MPMediaPlaylistCreationMetadata`, this represents the metadata to associate with the new playlist.
            let playlistCreationMetadata = MPMediaPlaylistCreationMetadata(name: playlistNameTextField.text ?? "New Playlist")
            playlistCreationMetadata.descriptionText = "This playlist was added via the Twister app. This playlist was from \(playlistName) on \(fromService.rawValue). Twisted on \(Date().description)"

            // Request the new or existing playlist from the device.
            MPMediaLibrary.default().getPlaylist(with: playlistUUID, creationMetadata: playlistCreationMetadata) { (playlist, error) in
                guard error == nil else { return }
                for item in toAdd {
                    //let url = URL(string:
                    let urlQueries = [URLQueryItem(name: "media", value: "music"),
                                      URLQueryItem(name: "entity", value: "song"),
                                      URLQueryItem(name: "term", value: item.0),
                                      URLQueryItem(name: "limit", value: "20")
                                    ]
                    var u = URLComponents(string: "https://itunes.apple.com/search")!
                    u.queryItems = urlQueries
                    //print(u.description)
                    let task = URLSession.shared.dataTask(with: u.url!) { (data, response, error) in
                        guard let data = data else { return }
                        if let fetchedDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
                            let fetchedArray = fetchedDict!["results"] as? [[String:Any]] {
                            for dict in fetchedArray {
                                //print(dict)
                                if let artist = dict ["artistName"] as? String {
                                    if (artist == item.1) {
                                        guard let trackId = dict["trackId"] else { return }
                                        let str = String(describing: trackId)
                                        print(str)
                                        playlist?.addItem(withProductID: str, completionHandler: { (error) in
                                            guard error == nil else {
                                                fatalError("An error occurred while adding an item to the playlist: \(error!.localizedDescription)")
                                            }
                                            NotificationCenter.default.post(name: MediaLibraryManager.libraryDidUpdate, object: nil)
                                        })
                                        return
                                    }
                                }
                            }
                        }
                    }
                    task.resume()
                    //var req = URLRequest(url: url!)
                    //let songQuery = MPMediaQuery.songs()
                    //songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: item.0, forProperty: MPMediaItemPropertyTitle))
                    //songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: item.1, forProperty: MPMediaItemPropertyArtist))
                    //print(songQuery.collections)
                    
                }
            }
        }
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
        return allPlaylists[fromSegControl.selectedSegmentIndex].count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistTableViewCell.identifier,
                                                       for: indexPath) as? PlaylistTableViewCell else {
            return UITableViewCell()
        }
        //cell.creatorNameLabel.text = allPlaylists[1][indexPath.item].1
        cell.playlistNameLabel.text = allPlaylists[fromSegControl.selectedSegmentIndex][indexPath.item].0
        cell.playlistId = allPlaylists[fromSegControl.selectedSegmentIndex][indexPath.item].1
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath) as! PlaylistTableViewCell
        playlistNameTextField.text = selectedCell.playlistNameLabel.text
    }
    
    
    
    
    
}
