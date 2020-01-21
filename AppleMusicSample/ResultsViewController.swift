//
//  ResultsViewController.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import MediaPlayer
import SpotifyKit

class ResultsViewController: UIViewController {

    @IBOutlet weak var songsTableView: UITableView!
    var songInformation: [(String, String)] = []
    var songProgress : [Int] = [] //0 in progress, 1 success, 2 failed
    var toService: StreamingService?
    var fromService: StreamingService?
    var playlistId: String?
    var playlistName: String?
    var newPlaylistName: String?
    
    var songResponse: [[[String:Any]]] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        songsTableView.delegate = self
        songsTableView.dataSource = self
        start()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    func start() {
    //actual logic
        guard let toService = toService else { return }
        guard let fromService = fromService else { return }
        guard let playlistId = playlistId else { return }
        guard let playlistName = playlistName else { return }
        guard let newPlaylistName = newPlaylistName else { return }
        if fromService == .spotify {
            spotifyManager.get(SpotifyPlaylist.self, id: playlistId) { (searchItem) in
                print(searchItem)
                guard let _ = searchItem.collectionTracks else {return}
                for item in searchItem.collectionTracks! {
                    print(item.name, "->" ,item.artist.name)
                    self.songInformation.append((item.name, item.artist.name))
                    self.songProgress.append(0)
                    self.songResponse.append([])
                    DispatchQueue.main.async { self.songsTableView.reloadData() }
                }
            }
        } else if fromService == .appleMusic {
            let myPlaylistQuery = MPMediaQuery.playlists()
            myPlaylistQuery.addFilterPredicate(MPMediaPropertyPredicate(value: UInt64(playlistId), forProperty: MPMediaPlaylistPropertyPersistentID))
            let fromPlaylist = (myPlaylistQuery.collections)![0]
            for item in fromPlaylist.items {
                print(item.title ?? "", "->", item.artist ?? "")
                songInformation.append((item.title ?? "" , item.artist ?? "" ))
                songProgress.append(0)
                songResponse.append([])
                DispatchQueue.main.async { self.songsTableView.reloadData() }
            }
            
        }
        
        //init the array
        
        if toService == .appleMusic {
            let playlistUUID = UUID()
            let playlistCreationMetadata = MPMediaPlaylistCreationMetadata(name: newPlaylistName)
            let df = DateFormatter()
            df.dateFormat = "MMM dd, yyyy h:mm a"
            playlistCreationMetadata.descriptionText = "This playlist was added via the Twister app. This playlist was entitled '\(playlistName)' on \(fromService.rawValue.capitalized). Twisted on \(df.string(from: Date()))"

            MPMediaLibrary.default().getPlaylist(with: playlistUUID, creationMetadata: playlistCreationMetadata) { (playlist, error) in
                guard error == nil else { return }
                for item in self.songInformation {
                    do {
                        sleep(3) //simply because of itunes rate limiting
                    }
                    sendiTunesRequest(songName: item.0, artistName: item.1) { (songId, dict) in
                        let i = self.songInformation.firstIndex { (check) -> Bool in
                            return check.0 == item.0 && check.1 == item.1
                        }
                        self.songResponse[i!] = dict
                        if songId == nil {
                            print(item.0, item.1)
                            self.songProgress[i!] = 2
                        }
                        //print(songId)
                        guard songId != nil else { return }
                        playlist?.addItem(withProductID: songId!, completionHandler: { (error) in
                            guard error == nil else {
                                self.songProgress[i!] = 2
                                fatalError("An error occurred while adding an item to the playlist: \(error!.localizedDescription)")
                            }
                            self.songProgress[i!] = 1
                            NotificationCenter.default.post(name: MediaLibraryManager.libraryDidUpdate, object: nil)
                        })
                        DispatchQueue.main.async { self.songsTableView.reloadData() }
                    }
                }
            }
        }

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

extension ResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songInformation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.identifier,
                                                       for: indexPath) as? SongTableViewCell else {
            return UITableViewCell()
        }
        //cell.creatorNameLabel.text = allPlaylists[1][indexPath.item].1
        cell.songNameLabel.text = songInformation[indexPath.item].0
        cell.artistNameLabel.text = songInformation[indexPath.item].1
        if songProgress[indexPath.item] == 0 { //in progress
            cell.activityIndicatorView.isHidden = false
            cell.activityIndicatorView.startAnimating()
            cell.completionImage.isHidden = true
        } else if songProgress[indexPath.item] == 1 { //sucess
            cell.activityIndicatorView.stopAnimating()
            cell.activityIndicatorView.isHidden = true
            cell.completionImage.isHidden = false
            cell.completionImage.image = UIImage(systemName: "checkmark.seal.fill")
            cell.completionImage.tintColor = .systemBlue
        } else if songProgress[indexPath.item] == 2 { //fail
            cell.activityIndicatorView.stopAnimating()
            cell.activityIndicatorView.isHidden = true
            cell.completionImage.isHidden = false
            cell.completionImage.image = UIImage(systemName: "xmark.seal.fill")
            cell.completionImage.tintColor = .yellow
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(songResponse[indexPath.item])
        if songProgress[indexPath.item] == 2 {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "songVC") as! SongReplacerViewController
            nextViewController.dict = songResponse[indexPath.item]
            self.present(nextViewController, animated: true) { }

        }
        
    }
    
    
    
}



