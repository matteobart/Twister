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

    var model: ResultsModel!
    var songInformation: [SongInformation] = []
    var songProgresses: [SongProgress] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        songsTableView.delegate = self
        songsTableView.dataSource = self
        createPlaylistButton.layer.cornerRadius = 10
        createPlaylistButton.layer.borderWidth = 1
        createPlaylistButton.backgroundColor = .systemGray
        createPlaylistButton.layer.borderColor = UIColor.systemGray.cgColor
        createPlaylistButton.setTitle("Create Playlist on " + model.toService.rawValue, for: .normal)
        getSongsFromPlaylist()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        songsTableView.unselectSelected()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        model.stopRequests = true
    }

    func getSongsFromPlaylist() {
        guard songInformation.isEmpty else { return }
        model.getPlaylist(dataHandler: { (songInfo) in
            self.songInformation.append(songInfo)
            self.songProgresses.append(.processing)
            DispatchQueue.main.async { self.songsTableView.reloadData() }
        }, completionHandler: {
            self.findSongs()
        })
    }

    func findSongs() {
        guard !songInformation.isEmpty else { // no songs in playlist
            let message = "'\(model.playlistName)' on \(model.fromService.rawValue) does not have any songs in it"
            let alert = UIAlertController(title: "No Songs Available", message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Okay", style: .default) { (_) in
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true) {}
            }
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        model.findSongs(songs: songInformation, dataHandler: { (index, songProgress) in
            self.songProgresses[index] = songProgress
            DispatchQueue.main.async { self.songsTableView.reloadData() }
        }, completionHandler: {
            self.createPlaylistButton.backgroundColor = appTint
            self.createPlaylistButton.layer.borderColor = appTint.cgColor
        })
    }

    func addToPlaylist(song: Song, index: Int) {
        model.toAddSongs[index] = song.value
        songProgresses[index] = .matchFound
        songsTableView.reloadData()
        let alert = UIAlertController(title: "Song Added",
                                      message: "'\(song.name)' by \(song.artist) has been added to your playlist",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Sounds good to me", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    @IBAction func createPlaylistButtonPressed(_ sender: UIButton) { //swiftlint:disable:this function_body_length
        guard model.readyToCreatePlaylist else {
            let alert = UIAlertController(title: "Songs are not ready",
                                          message: """
                                                   The songs are still being searched for on \(model.toService.rawValue)
                                                   """,
                                          preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
            alert.addAction(closeAction)
            present(alert, animated: true, completion: nil)
            return
        }
        //check to make sure at least one song is even available
        if !songProgresses.contains(.matchFound) && !songProgresses.contains(.songsFound) {
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
        if !songProgresses.contains(.matchFound) && songProgresses.contains(.songsFound) {
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

    func createPlaylist() { // swiftlint:disable:this function_body_length
        let count = Counter()
        let totalCount = songProgresses.reduce(0) { (current, val) -> Int in
            if val == .matchFound {
                return current + 1
            }
            return current
        }
        model.createPlaylist(dataHandler: { (trackName, isSuccess) in
            DispatchQueue.main.async {
                count.increment()
                self.createPlaylistProgressView.progress = Float(count.value)/Float(totalCount)
                if isSuccess {
                    self.addedSongLabel.text = "Added '\(trackName)'"
                } else {
                    let message = "\(trackName) could not be added to the playlist"
                    let alert = UIAlertController(title: "Track could not be added",
                                                  message: message,
                                                  preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                    }
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }, completionHandler: { (playlistCreated) in
                DispatchQueue.main.async {
                if playlistCreated {
                    let message = "'\(self.model.playlistName)' has been created on \(self.model.toService.rawValue)"
                    let alert = UIAlertController(title: "Playlist Complete",
                                                  message: message,
                                                  preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Sweet!", style: .default) { (_) in
                        self.navigationController?.popViewController(animated: true)
                        self.dismiss(animated: true) {}
                    }
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Something went wrong",
                                                  message: """
                                                           '\(self.model.playlistName)' could not be created on \
                                                           \(self.model.toService.rawValue)
                                                           """,
                                                  preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                        self.createPlaylistButton.isUserInteractionEnabled = true
                        self.createPlaylistButton.isEnabled = true
                        self.createPlaylistButton.setTitle("Try to Create Playlist Again", for: .normal)
                    }
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })
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
        if songProgresses[indexPath.item] == .processing { //in progress
            cell.activityIndicatorView.isHidden = false
            cell.activityIndicatorView.startAnimating()
            cell.completionImage.isHidden = true
        } else if songProgresses[indexPath.item] == .matchFound { //sucess
            cell.activityIndicatorView.stopAnimating()
            cell.activityIndicatorView.isHidden = true
            cell.completionImage.isHidden = false
            cell.completionImage.image = UIImage(systemName: "checkmark.square.fill")
            cell.completionImage.tintColor = .systemBlue
        } else if songProgresses[indexPath.item] == .songsFound { //matches
            cell.activityIndicatorView.stopAnimating()
            cell.activityIndicatorView.isHidden = true
            cell.completionImage.isHidden = false
            cell.completionImage.image = UIImage(systemName: "questionmark.square.fill")
            cell.completionImage.tintColor = .systemYellow
        } else if songProgresses[indexPath.item] == .notFound { //no matches
            cell.activityIndicatorView.stopAnimating()
            cell.activityIndicatorView.isHidden = true
            cell.completionImage.isHidden = false
            cell.completionImage.image = UIImage(systemName: "exclamationmark.square.fill")
            cell.completionImage.tintColor = .systemOrange
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print(songResponse[indexPath.item])
        if songProgresses[indexPath.item] == .songsFound {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "songVC")
            guard let songReplacerVC = nextViewController as? SongReplacerViewController else { return }
            songReplacerVC.index = indexPath.item
            songReplacerVC.songInformation = songInformation[indexPath.item]
            songReplacerVC.replacementSongs = model.songResponse[indexPath.item]
            songReplacerVC.resultsVC = self
            songReplacerVC.title = "Songs on " + String(describing: model.toService)
            self.present(songReplacerVC, animated: true) { }
        } else if songProgresses[indexPath.item] == .notFound {
            let alert = UIAlertController(title: "Song not found",
                                          message: """
                                                   \(model.toService.rawValue) could not find any songs that matched \
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
