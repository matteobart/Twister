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
    @IBOutlet weak var createPlaylistButton: UIButton!
    
    var songInformation: [(name: String, artist: String, album: String)] = []
    var songProgress : [Int] = [] //0 in progress, 1 success, 2 failed
    var toService: StreamingService?
    var fromService: StreamingService?
    var playlistId: String?
    var playlistName: String?
    var newPlaylistName: String?
    var newPlaylistId: UUID?
    
    var songResponse: [[Song]] = []
    
    //var toAddSongs: [SongValue?] = []
    var spotifyTracks: [SpotifyTrack?] = [] //used if creating a spotify playlist
    var appleIds: [String?] = [] //used if creating an apple music playlist

    let sam = DispatchSemaphore(value: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        songsTableView.delegate = self
        songsTableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let fromService = fromService else { return }
        guard let playlistId = playlistId else { return }
        
        if fromService == .spotify {
            sam.wait()
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
                self.sam.signal()
            }
        } else if fromService == .appleMusic {
            sam.wait()
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
            sam.signal()
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let toService = toService else { return }
        
        let group = DispatchGroup()
        
        if toService == .appleMusic {
            for _ in songInformation { appleIds.append(nil) }
            for i in 0..<self.songInformation.count {
                let tuple = songInformation[i]
                group.enter()
                do {
                    sleep(3) //simply because of itunes rate limiting
                }
                sendiTunesRequest(songName: tuple.name, artistName: tuple.artist) { (songId, dict) in
                    group.leave()
                    self.appleIds[i] = songId
                    var possibleSongs: [Song] = []
                    for item in dict {
                        possibleSongs.append(Song(name: item["trackName"] as? String ?? "",
                                                  artist: item["artistName"] as? String ?? "",
                                                  album: item["collectionName"] as? String ?? "",
                                                  value: SongValue.appleId(String(describing: item["trackId"] as! Int))))
                    }
                    self.songResponse[i] = possibleSongs
                    if songId != nil {
                        self.songProgress[i] = 1
                    } else {
                        print("WARNING: Apple could not find a perfect match for \(tuple.name)")
                        self.songProgress[i] = 2
                    }
                    DispatchQueue.main.async { self.songsTableView.reloadData() }
                }
            }
        } else if toService == .spotify {
            for _ in songInformation { spotifyTracks.append(nil) }
            for index in 0..<songInformation.count {
                let tuple = songInformation[index]
                let cleanedTitle = tuple.name.replacingOccurrences(of: "\\([^()]*\\)", with: "", options: [.regularExpression])
                let searchTerm = (cleanedTitle + " " + tuple.artist).replacingOccurrences(of: "&", with: "and").replacingOccurrences(of: "?", with: "").folding(options: .diacriticInsensitive, locale: nil).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                group.enter()
                spotifyManager.find(SpotifyTrack.self, searchTerm) { (tracks) in
                    group.leave()
                    guard let tracks = tracks else {
                        self.songProgress[index] = 2
                        return
                    }
                    if let track = tracks.first { // may want to change this to match song title + author
                        self.spotifyTracks[index] = track
                        self.songProgress[index] = 1
                    } else {
                        print("WARNING: Spotify can't find \(tuple.name)")
                        self.songProgress[index] = 2
                    }
                    var possibleSongs: [Song] = []
                    for track in tracks {
                        possibleSongs.append(Song(name: track.name, artist: track.artist.name, album: track.album?.name ?? "", value: SongValue.spotifyTrack(track)))
                    }
                    self.songResponse[index] = possibleSongs

                    DispatchQueue.main.async { self.songsTableView.reloadData() }
                }
                
            }
        }
        
        group.notify(queue: .main) {
            self.createPlaylistButton.isUserInteractionEnabled = true
            self.createPlaylistButton.isEnabled = true
        }
    }
    
    //song will either be String (if creating apple music) or SpotifyTrack (if creating spotify)
    func addToPlaylist(song: Song, index: Int) {
        switch song.value {
        case .appleId(let id): //toService: appleMusic
            appleIds[index] = id
        case .spotifyTrack(let track): //toService: spotify
            spotifyTracks[index] = track
        }
    }
    
    @IBAction func createPlaylistButtonPressed(_ sender: UIButton) {
        guard let fromService = fromService else { return }
        //let group = DispatchGroup()
        if toService == .appleMusic {
            let playlistUUID = UUID()
            let playlistMetadata = MPMediaPlaylistCreationMetadata(name: newPlaylistName ?? "New Twisted Playlist")
            let df = DateFormatter()
            df.dateFormat = "MMM dd, yyyy h:mm a"
            playlistMetadata.descriptionText = "This playlist was added via the Twister app. This playlist was entitled '\(playlistName ?? "")' from \(fromService.rawValue.capitalized). Twisted on \(df.string(from: Date()))"
            //group.enter()
            MPMediaLibrary.default().getPlaylist(with: playlistUUID, creationMetadata: playlistMetadata) { (playlist, error) in
                guard error == nil else {
                    print("Playlist could not be created")
                    //group.leave()
                    return
                }
                guard let playlist = playlist else { return }
                let serialQueue = DispatchQueue(label: "createAppleMusicPlaylist")
                for songId in self.appleIds.compactMap({ $0 }) {
                    serialQueue.async { //add to a serial async queue
                        playlist.addItem(withProductID: songId) { (error) in
                            if error != nil {
                                print("ERROR: Could not add \(songId) to the playlist!")
                            }
                            NotificationCenter.default.post(name: MediaLibraryManager.libraryDidUpdate, object: nil)
                        }
                    }
                }
            }
        } else if toService == .spotify {
            spotifyManager.createPlaylist(playlistName: newPlaylistName ?? "New Twisted Playlist") { (playlistId) in
                guard let playlistId = playlistId else {
                    print("Playlist could not be made")
                    return
                }
                spotifyManager.addSongsToPlaylist(playlistId: playlistId, tracks: self.spotifyTracks.compactMap { $0 }) { (success) in
                    if !success {
                        print("ERROR: Addings tracks to spotify")
                    }
                }
            }
        }
        //group.notify(queue: .main) {
        //    self.dismiss(animated: true) {
                
        //    }
        //}
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
            nextViewController.index = indexPath.item
            nextViewController.originalSongData = songInformation[indexPath.item]
            nextViewController.replacementSongs = songResponse[indexPath.item]
            nextViewController.resultsVC = self
            self.present(nextViewController, animated: true) { }

        }
        
    }
    
    
    
}
