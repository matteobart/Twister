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
    
    var songInformation: [(String, String, String)] = [] // (Song, Artist, Album)
    var songProgress : [Int] = [] //0 in progress, 1 success, 2 failed
    var toService: StreamingService?
    var fromService: StreamingService?
    var playlistId: String?
    var playlistName: String?
    var newPlaylistName: String?
    var newPlaylistId: UUID?
    
    var songResponse: [[[String:Any]]] = []
    
    var spotifyTracks: [SpotifyTrack?] = [] //used if creating a spotify playlist
    var appleIds: [String?] = [] //used if creating an apple music playlist

    override func viewDidLoad() {
        super.viewDidLoad()
        songsTableView.delegate = self
        songsTableView.dataSource = self
        start()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    //songId will either be String (if creating apple music) or SpotifyTrack (if creating spotify)
    func addToPlaylist(songId: Any) {
        if toService == .appleMusic {
            guard let newPlaylistId = newPlaylistId else { return }
            MPMediaLibrary.default().getPlaylist(with: newPlaylistId, creationMetadata: nil) { (playlist, error) in
                guard error == nil else { return }
                playlist?.addItem(withProductID: songId as! String, completionHandler: { (error) in
                    guard error == nil else { return }
                })
            }
        }
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
                    self.songInformation.append((item.name, item.artist.name, item.album?.name ?? ""))
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
                songInformation.append((item.title ?? "" , item.artist ?? "", item.albumTitle ?? "" ))
                songProgress.append(0)
                songResponse.append([])
                DispatchQueue.main.async { self.songsTableView.reloadData() }
            }
            
        }
        
        //init the array
        
        if toService == .appleMusic {
            let playlistUUID = UUID()
            newPlaylistId = playlistUUID
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
        } else if toService == .spotify {
            var spotifyTracks: [SpotifyTrack?] = []
            for _ in songInformation { spotifyTracks.append(nil) }
            let group = DispatchGroup()
            spotifyManager.createPlaylist(playlistName: newPlaylistName) { (id) in
                guard let id = id else { return }
                for item in self.songInformation {
                    let cleanedTitle = item.0.replacingOccurrences(of: "\\([^()]*\\)", with: "", options: [.regularExpression])
                    print(cleanedTitle)
                    group.enter()
                    let searchTerm = (cleanedTitle + " " + item.1).replacingOccurrences(of: "&", with: "and").replacingOccurrences(of: "?", with: "").folding(options: .diacriticInsensitive, locale: nil).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    spotifyManager.find(SpotifyTrack.self, searchTerm) { (tracks) in
                        let index = self.songInformation.firstIndex { (check) -> Bool in
                            return check.0 == item.0 && check.1 == item.1
                        }
                        guard let tracks = tracks else {
                            self.songProgress[index!] = 2
                            return
                        }
                        var spotifyReturn: [[String: Any]] = []
                        for i in 0..<tracks.count {
                            var result: [String: Any] = [:]
                            result["artistName"] = tracks[i].artist.name
                            result["collectionName"] = tracks[i].album?.name ?? ""
                            result["trackName"] = tracks[i].name
                            result["trackId"] = tracks[i].uri
                            spotifyReturn.append(result)
                        }
                        self.songResponse[index!] = spotifyReturn
                        if let track = tracks.first {
                            spotifyTracks[index!] = track
                            //semaphore.signal()
                            print(track.name, "==", cleanedTitle)
                            self.songProgress[index!] = 1
 
                        } else {
                            print("Can't find: " + item.0)
                            spotifyManager.find(SpotifyTrack.self, cleanedTitle + " " + item.1) { (tracks) in
                                
                            }
                            self.songProgress[index!] = 2
                        }
                        DispatchQueue.main.async { self.songsTableView.reloadData() }
                        group.leave()
                    }
                    
                }
                group.notify(queue: .main) {
                    spotifyManager.addSongsToPlaylist(playlistId: id, tracks: spotifyTracks.compactMap{ $0 })  { (success) in
                        if success {
                            print("lit")
                        } else {
                            print("not lit")
                        }
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
            nextViewController.artistName = songInformation[indexPath.item].1
            nextViewController.songName = songInformation[indexPath.item].0
            nextViewController.albumName = songInformation[indexPath.item].2
            nextViewController.resultsVC = self
            self.present(nextViewController, animated: true) { }

        }
        
    }
    
    
    
}
