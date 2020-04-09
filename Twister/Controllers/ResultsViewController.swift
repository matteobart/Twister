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
    @IBOutlet weak var createPlaylistProgressView: UIProgressView!
    @IBOutlet weak var findSongsLabel: UILabel!
    
    var songInformation: [(name: String, artist: String, album: String)] = []
    var songProgress : [Int] = [] //0 in progress, 1 success, 2 failed
    var toService: StreamingService?
    var fromService: StreamingService?
    var playlistId: String?
    var playlistName: String?
    var newPlaylistName: String?
    var newPlaylistId: UUID?
    
    var songResponse: [[Song]] = []
    
    var toAddSongs: [SongValue?] = []

    let sam = DispatchSemaphore(value: 0) // used for set up

    override func viewDidLoad() {
        super.viewDidLoad()
        songsTableView.delegate = self
        songsTableView.dataSource = self
        
        findSongsLabel.text = "Finding Songs on " + toService!.rawValue.capitalized
        createPlaylistButton.setTitle("Create Playlist on " + toService!.rawValue.capitalized, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let fromService = fromService else { return }
        guard let playlistId = playlistId else { return }
        
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
                self.sam.signal()
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
            sam.signal()
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let toService = toService else { return }
        
        sam.wait() // don't start this one till viewWillAppear is finished
        
        let group = DispatchGroup()

        for _ in songInformation { toAddSongs.append(nil); group.enter() }

        if toService == .appleMusic {
            DispatchQueue.global().async {
            for i in 0..<self.songInformation.count {
                let tuple = self.songInformation[i]
                do {
                    sleep(3) //simply because of itunes rate limiting
                }
                sendiTunesRequest(songName: tuple.name, artistName: tuple.artist) { (songId, dict) in
                    group.leave()
                    if let songId = songId { // if the correct song is found
                        self.toAddSongs[i] = .appleId(songId)
                        self.songProgress[i] = 1
                    } else {
                        print("WARNING: Apple could not find a perfect match for \(tuple.name)")
                        self.songProgress[i] = 2
                    }
                    var possibleSongs: [Song] = []
                    for item in dict {
                        possibleSongs.append(Song(name: item["trackName"] as? String ?? "",
                                                  artist: item["artistName"] as? String ?? "",
                                                  album: item["collectionName"] as? String ?? "",
                                                  value: SongValue.appleId(String(describing: item["trackId"] as! Int))))
                    }
                    self.songResponse[i] = possibleSongs
                    DispatchQueue.main.async { self.songsTableView.reloadData() }
                }
            }
            }
        } else if toService == .spotify {
            DispatchQueue.global().async {
            for index in 0..<self.songInformation.count {
                let tuple = self.songInformation[index]
                let cleanedTitle = tuple.name.replacingOccurrences(of: "\\([^()]*\\)", with: "", options: [.regularExpression])
                let searchTerm = (cleanedTitle + " " + tuple.artist).replacingOccurrences(of: "&", with: "and").replacingOccurrences(of: "?", with: "").folding(options: .diacriticInsensitive, locale: nil).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                spotifyManager.find(SpotifyTrack.self, searchTerm) { (tracks) in
                    group.leave()
                    guard let tracks = tracks else {
                        self.songProgress[index] = 2
                        return
                    }
                    if let track = tracks.first { // may want to change this to match song title + author
                        self.toAddSongs[index] = .spotifyTrack(track)
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
        }
        
        group.notify(queue: .main) {
            self.createPlaylistButton.isUserInteractionEnabled = true
            self.createPlaylistButton.isEnabled = true
        }
    }
    
    //song will either be String (if creating apple music) or SpotifyTrack (if creating spotify)
    func addToPlaylist(song: Song, index: Int) {
        toAddSongs[index] = song.value
    }
    
    
    @IBAction func exitButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true) {
            
        }
    }
    
    @IBAction func createPlaylistButtonPressed(_ sender: UIButton) {
        var completeCount = 0
        var totalCount = 0
        
        guard let fromService = fromService else { return }
        let group = DispatchGroup()
        if toService == .appleMusic {
            let playlistUUID = UUID()
            let playlistMetadata = MPMediaPlaylistCreationMetadata(name: newPlaylistName ?? "New Twisted Playlist")
            let df = DateFormatter()
            df.dateFormat = "MMM dd, yyyy h:mm a"
            playlistMetadata.descriptionText = "This playlist was added via the Twister app. This playlist was entitled '\(playlistName ?? "")' from \(fromService.rawValue.capitalized). Twisted on \(df.string(from: Date()))"
            group.enter() // A
            MPMediaLibrary.default().getPlaylist(with: playlistUUID, creationMetadata: playlistMetadata) { (playlist, error) in
                guard error == nil else {
                    print("Playlist could not be created")
                    group.leave() // A
                    return
                }
                guard let playlist = playlist else { return }
                let serialQueue = DispatchQueue(label: "createAppleMusicPlaylist")
                for songValue in self.toAddSongs.compactMap({ $0 }) {
                    group.enter() // B
                    totalCount+=1
                    serialQueue.async { //add to a serial async queue
                        let songId: String = {
                            switch songValue {
                            case .appleId(let id):
                                return id
                            default:
                                return ""
                            }
                        }()
                        playlist.addItem(withProductID : songId) { (error) in
                            group.leave() // B
                            completeCount+=1
                            DispatchQueue.main.async {
                                self.createPlaylistProgressView.progress = Float(completeCount)/Float(totalCount)
                            }
                            if error != nil {
                                print("ERROR: Could not add \(songId) to the playlist!")
                            }
                            NotificationCenter.default.post(name: MediaLibraryManager.libraryDidUpdate, object: nil)
                        }
                    }
                }
                group.leave() // A
            }
        } else if toService == .spotify {
            group.enter() // C
            spotifyManager.createPlaylist(playlistName: newPlaylistName ?? "New Twisted Playlist") { (playlistId) in
                guard let playlistId = playlistId else {
                    print("Playlist could not be made")
                    group.leave() // C
                    return
                }
                group.enter() // D
                let tracks = self.toAddSongs.map { (songVal) -> SpotifyTrack? in
                    switch songVal {
                    case .spotifyTrack(let track):
                        return track
                    default:
                        return nil
                    }
                }
                spotifyManager.addSongsToPlaylist(playlistId: playlistId, tracks: tracks.compactMap { $0 }) { (success) in
                    group.leave() // D
                    if !success {
                        print("ERROR: Addings tracks to spotify")
                    }
                }
                group.leave() // C
            }
        }
        group.notify(queue: .main) {
            self.dismiss(animated: true) {
                
            }
        }
    }
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
