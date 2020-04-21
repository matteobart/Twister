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
    @IBOutlet weak var addedSongLabel: UILabel!
    var songInformation: [SongInformation] = []
    var songProgress: [Int] = [] //0 in progress, 1 success, 2 matches, 3 failed
    var toService: StreamingService?
    var fromService: StreamingService?
    var playlistId: String?
    var playlistName: String?
    var newPlaylistName: String?
    var newPlaylistId: UUID?
    var readyToCreatePlaylist = false
    var songResponse: [[Song]] = []
    var toAddSongs: [SongValue?] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        songsTableView.delegate = self
        songsTableView.dataSource = self
        createPlaylistButton.layer.cornerRadius = 10
        createPlaylistButton.layer.borderWidth = 1
        createPlaylistButton.backgroundColor = .systemGray
        createPlaylistButton.layer.borderColor = UIColor.systemGray.cgColor
        createPlaylistButton.setTitle("Create Playlist on " + toService!.rawValue.capitalized, for: .normal)
        setUp()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        songsTableView.unselectSelected()
    }
    func checkForPlaylistPagnation(nextPage: String?, completionHandler: @escaping (() -> Void)) {
        if nextPage == nil {
            completionHandler()
        } else {
            spotifyManager.get(SpotifyPlaylist.Tracks.self, url: nextPage!) { (pagingObject) in
                for item in pagingObject.items ?? [] {
                    print(item.track.name, "->", item.track.artist.name)
                    self.songInformation.append(
                        SongInformation(name: item.track.name,
                                        artist: item.track.artist.name,
                                        album: item.track.album?.name ?? ""))
                    self.songProgress.append(0)
                    self.songResponse.append([])
                }
                DispatchQueue.main.async { self.songsTableView.reloadData(); self.songsTableView.layoutIfNeeded() }
                self.checkForPlaylistPagnation(nextPage: pagingObject.next, completionHandler: completionHandler)
            }
        }
    }
    func setUp() {
        guard let fromService = fromService else { return }
        guard let playlistId = playlistId else { return }
        guard toAddSongs.isEmpty else { return }
        guard songInformation.isEmpty else { return }
        if fromService == .spotify {
            spotifyManager.get(SpotifyPlaylist.self, id: playlistId) { (searchItem) in
                print(searchItem)
                guard searchItem.collectionTracks != nil else { return }
                for item in searchItem.collectionTracks! {
                    print(item.name, "->", item.artist.name)
                    self.songInformation.append(
                        SongInformation(name: item.name,
                                        artist: item.artist.name,
                                        album: item.album?.name ?? ""))
                    self.songProgress.append(0)
                    self.songResponse.append([])
                }
                DispatchQueue.main.async { self.songsTableView.reloadData() }
                self.checkForPlaylistPagnation(nextPage: searchItem.nextURL) {
                    self.findSongsOnToService()
                }
            }
        } else if fromService == .appleMusic {
            let myPlaylistQuery = MPMediaQuery.playlists()
            myPlaylistQuery.addFilterPredicate(
                MPMediaPropertyPredicate(value: UInt64(playlistId), forProperty: MPMediaPlaylistPropertyPersistentID))
            let fromPlaylist = (myPlaylistQuery.collections)![0]
            for item in fromPlaylist.items {
                print(item.title ?? "", "->", item.artist ?? "")
                songInformation.append(
                    SongInformation(name: item.title ?? "",
                                    artist: item.artist ?? "",
                                    album: item.albumTitle ?? ""))
                songProgress.append(0)
                songResponse.append([])
                DispatchQueue.main.async { self.songsTableView.reloadData() }
            }

            findSongsOnToService()
        }
    }
    func findSongsOnToService() {
        guard let toService = toService else { return }
        guard toAddSongs.isEmpty else { return }
        guard !songInformation.isEmpty else { // no songs in playlist
            let message = "'\(playlistName!)' on \(fromService!.rawValue) does not have any songs in it"
            let alert = UIAlertController(title: "No Songs Available", message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Okay", style: .default) { (_) in
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true) {}
            }
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        let group = DispatchGroup()

        for _ in songInformation { toAddSongs.append(nil); group.enter() }

        if toService == .appleMusic {
            DispatchQueue.global().async {
            for index in 0..<self.songInformation.count {
                if self.isControllerNotActive() {
                   break
                }
                let tuple = self.songInformation[index]
                do {
                    sleep(3) //simply because of itunes rate limiting
                }
                sendiTunesSongRequest(songName: tuple.name, artistName: tuple.artist) { (songRequest) in
                    group.leave()
                    guard let songRequest = songRequest else { self.songProgress[index] = 3; return }
                    guard !songRequest.results.isEmpty else { self.songProgress[index] = 3; return }
                    self.songProgress[index] = 2
                    var possibleSongs: [Song] = []
                    for song in songRequest.results {
                        possibleSongs.append(song.toSong)
                    }
                    self.songResponse[index] = possibleSongs
                    for song in possibleSongs {
                        if tuple.name.isEqualStrippedString(song.name)
                        && tuple.artist.isPartialMatch(song.artist) {
                            self.toAddSongs[index] = song.value
                            self.songProgress[index] = 1
                            break
                        }
                    }
                    DispatchQueue.main.async { self.songsTableView.reloadData() }
                }
            }
            }
        } else if toService == .spotify {
            DispatchQueue.global().async {
            for index in 0..<self.songInformation.count {
                let tuple = self.songInformation[index]
                let cleanedTitle = tuple.name.replacingOccurrences(of: "\\([^()]*\\)",
                                                                   with: "",
                                                                   options: [.regularExpression])
                let searchTerm = (cleanedTitle + " " + tuple.artist)
                                    .replacingOccurrences(of: "&", with: "and")
                                    .replacingOccurrences(of: "?", with: "")
                                    .folding(options: .diacriticInsensitive, locale: nil)
                                    .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                spotifyManager.find(SpotifyTrack.self, searchTerm) { (tracks) in
                    group.leave()
                    guard let tracks = tracks else {
                        print("WARNING: Spotify can't find \(tuple.name)")
                        self.songProgress[index] = 3
                        return
                    }
                    guard !tracks.isEmpty else {
                        print("WARNING: Spotify can't find \(tuple.name)")
                        self.songProgress[index] = 3
                        return
                    }
                    self.songProgress[index] = 2
                    for track in tracks {
                        if track.artist.name.isEqualStrippedString(tuple.artist)
                        && track.name.isPartialMatch(tuple.name) {
                            self.toAddSongs[index] = .spotifyTrack(track)
                            self.songProgress[index] = 1
                            break
                        }
                    }
                    var possibleSongs: [Song] = []
                    for track in tracks {
                        possibleSongs.append(Song(name: track.name,
                                                  artist: track.artist.name,
                                                  album: track.album?.name ?? "",
                                                  value: SongValue.spotifyTrack(track)))
                    }
                    self.songResponse[index] = possibleSongs

                    DispatchQueue.main.async { self.songsTableView.reloadData() }
                }
            }
        }
        }
        group.notify(queue: .main) {
            self.createPlaylistButton.backgroundColor = appTint
            self.createPlaylistButton.layer.borderColor = appTint.cgColor
            self.readyToCreatePlaylist = true
        }
    }
    func isControllerNotActive () -> Bool {
        DispatchQueue.main.sync {
            return self.navigationController?.visibleViewController == nil
        }
    }
    func addToPlaylist(song: Song, index: Int) {
        toAddSongs[index] = song.value
        songProgress[index] = 1
        songsTableView.reloadData()
        let alert = UIAlertController(title: "Song Added",
                                      message: "'\(song.name)' by \(song.artist) has been added to your playlist",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Sounds good to me", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    func getSongNameFromSongValue(song: SongValue) -> String {
        for index in 0..<toAddSongs.count where song == toAddSongs[index] {
            return songInformation[index].name
        }
        return ""
    }
    @IBAction func createPlaylistButtonPressed(_ sender: UIButton) {
        guard readyToCreatePlaylist else {
            let alert = UIAlertController(title: "Songs are not ready",
                                          message: "The songs are still being searched for on " + toService!.rawValue,
                                          preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
            alert.addAction(closeAction)
            present(alert, animated: true, completion: nil)
            return
        }
        //check to make sure at least one song is even available
        if !songProgress.contains(1) && !songProgress.contains(2) {
            let alert = UIAlertController(title: "No songs to add",
                                          message: "No matches were found for your songs. Try a different playlist.",
                                          preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Okay", style: .cancel) { (_) in
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true) {}
            }
            alert.addAction(closeAction)
            present(alert, animated: true, completion: nil)
            return
        }
        if !songProgress.contains(1) && songProgress.contains(2) {
            let alert = UIAlertController(title: "Please choose replacement songs",
                                          message: """
                                                   No perfect matches were found for your songs. Tap on songs that \
                                                   are yellow to choose from similar songs or try a different playlist.
                                                   """,
                                          preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Try another playlist", style: .cancel) { (_) in
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true) {}
            }
            let stayAction = UIAlertAction(title: "Choose replacements", style: .default, handler: nil)
            alert.addAction(closeAction)
            alert.addAction(stayAction)
            present(alert, animated: true, completion: nil)
            return
        }
        createPlaylistProgressView.transform = CGAffineTransform(scaleX: 1, y: 2)
        createPlaylistProgressView.isHidden = false
        createPlaylistButton.setTitle("Playlist in Progress", for: .normal)
        createPlaylistButton.isUserInteractionEnabled = false
        addedSongLabel.text = "Adding Songs to Playlist"
        addedSongLabel.isHidden = false
        createPlaylist()
    }
    /// Will be called by createPlaylistButtonPressed
    func createPlaylist() {
        let count = Counter()
        var totalCount = 0
        guard let fromService = fromService else { return }
        let group = DispatchGroup()
        if toService == .appleMusic {
            let playlistUUID = UUID()
            let playlistMetadata = MPMediaPlaylistCreationMetadata(name: newPlaylistName ?? "New Twisted Playlist")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy h:mm a"
            playlistMetadata.descriptionText = """
                                               This playlist was added via the Twister app. This playlist was entitled \
                                               '\(playlistName ?? "")' from \(fromService.rawValue.capitalized). \
                                               Twisted on \(dateFormatter.string(from: Date()))
                                               """
            group.enter() // A
            MPMediaLibrary.default().getPlaylist(with: playlistUUID,
                                                 creationMetadata: playlistMetadata) { (playlist, error) in
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
                            case .appleId(let identifier):
                                return identifier
                            default:
                                return ""
                            }
                        }()
                        playlist.addItem(withProductID: songId) { (error) in
                            group.leave() // B
                            count.increment()
                            DispatchQueue.main.async {
                                self.createPlaylistProgressView.progress = Float(count.value)/Float(totalCount)
                                self.addedSongLabel.text = "Added '\(self.getSongNameFromSongValue(song: songValue))'"
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
                spotifyManager.addSongsToPlaylist(playlistId: playlistId,
                                                  tracks: tracks.compactMap { $0 }) { (success) in
                    group.leave() // D
                    DispatchQueue.main.async {
                        self.createPlaylistProgressView.progress = 1.0
                    }
                    if !success {
                        print("ERROR: Addings tracks to spotify")
                    }
                }
                group.leave() // C
            }
        }
        group.notify(queue: .main) {
            let message = "'\(self.playlistName!)' has been created on \(self.toService!.rawValue)"
            let alert = UIAlertController(title: "Playlist Complete",
                                          message: message,
                                          preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Sweet!", style: .default) { (_) in
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true) {}
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension ResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songInformation.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.identifier,
                                                       for: indexPath) as? SongTableViewCell else {
            return UITableViewCell()
        }
        cell.songNameLabel.text = songInformation[indexPath.item].name
        cell.artistNameLabel.text = songInformation[indexPath.item].artist
        if songProgress[indexPath.item] == 0 { //in progress
            cell.activityIndicatorView.isHidden = false
            cell.activityIndicatorView.startAnimating()
            cell.completionImage.isHidden = true
        } else if songProgress[indexPath.item] == 1 { //sucess
            cell.activityIndicatorView.stopAnimating()
            cell.activityIndicatorView.isHidden = true
            cell.completionImage.isHidden = false
            cell.completionImage.image = UIImage(systemName: "checkmark.square.fill")
            cell.completionImage.tintColor = .systemBlue
        } else if songProgress[indexPath.item] == 2 { //matches
            cell.activityIndicatorView.stopAnimating()
            cell.activityIndicatorView.isHidden = true
            cell.completionImage.isHidden = false
            cell.completionImage.image = UIImage(systemName: "questionmark.square.fill")
            cell.completionImage.tintColor = .systemYellow
        } else if songProgress[indexPath.item] == 3 { //no matches
            cell.activityIndicatorView.stopAnimating()
            cell.activityIndicatorView.isHidden = true
            cell.completionImage.isHidden = false
            cell.completionImage.image = UIImage(systemName: "exclamationmark.square.fill")
            cell.completionImage.tintColor = .systemOrange
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(songResponse[indexPath.item])
        if songProgress[indexPath.item] == 2 {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "songVC")
            guard let songReplacerVC = nextViewController as? SongReplacerViewController else { return }
            songReplacerVC.index = indexPath.item
            songReplacerVC.songInformation = songInformation[indexPath.item]
            songReplacerVC.replacementSongs = songResponse[indexPath.item]
            songReplacerVC.resultsVC = self
            songReplacerVC.title = "Songs on " + String(describing: toService)
            self.present(songReplacerVC, animated: true) { }
        } else if songProgress[indexPath.item] == 3 {
            let alert = UIAlertController(title: "Song not found",
                                          message: """
                                                   \(toService!.rawValue) could not find any songs that matched \
                                                   this song
                                                   """,
                                          preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Aw shucks!", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true) {
                self.songsTableView.unselectSelected()
            }
        } else {
            self.songsTableView.unselectSelected()
        }
    }
}
