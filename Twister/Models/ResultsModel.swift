//
//  ResultsModel.swift
//  Twister
//
//  Created by Matteo Bart on 4/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import SpotifyKit
import MediaPlayer

class ResultsModel {
    var toService: StreamingService
    var fromService: StreamingService
    var playlistId: String
    var playlistName: String
    var newPlaylistName: String
    var readyToCreatePlaylist = false
    var songResponse: [[Song]] = []
    var toAddSongs: [SongValue?] = []

    var group = DispatchGroup()
    var stopRequests = false

    init(fromService: StreamingService, toService: StreamingService,
         playlistName: String, playlistId: String, newPlaylistName: String) {
        self.fromService = fromService
        self.toService = toService
        self.playlistName = playlistName
        self.playlistId = playlistId
        self.newPlaylistName = newPlaylistName
    }

    func getPlaylist(dataHandler: @escaping (SongInformation) -> Void,
                     completionHandler: @escaping () -> Void) {
        switch fromService {
        case .appleMusic:
            getAppleMusicPlaylist(dataHandler: dataHandler, completionHandler: completionHandler)
        case .spotify :
            getSpotifyPlaylist(dataHandler: dataHandler, completionHandler: completionHandler)
        }
    }

    private func getAppleMusicPlaylist(dataHandler: (SongInformation) -> Void,
                                       completionHandler: () -> Void) {
        let myPlaylistQuery = MPMediaQuery.playlists()
        myPlaylistQuery.addFilterPredicate(
            MPMediaPropertyPredicate(value: UInt64(playlistId), forProperty: MPMediaPlaylistPropertyPersistentID))
        let playlist = (myPlaylistQuery.collections)![0]
        for item in playlist.items {
            let songInfo = SongInformation(name: item.title ?? "",
                                           artist: item.artist ?? "",
                                           album: item.albumTitle ?? "")
            dataHandler(songInfo)
        }
        completionHandler()

    }

    private func getSpotifyPlaylist(dataHandler: @escaping (SongInformation) -> Void,
                                    completionHandler: @escaping () -> Void) {
        spotifyManager.get(SpotifyPlaylist.self, id: playlistId) { (playlistSearchItem) in
            guard playlistSearchItem.collectionTracks != nil else { return }
            for item in playlistSearchItem.collectionTracks! {
                let songInfo = SongInformation(name: item.name,
                                               artist: item.artist.name,
                                               album: item.album?.name ?? "")
                dataHandler(songInfo)
            }
            self.checkForSpotifyPlaylistPagnation(nextPage: playlistSearchItem.nextURL,
                                                  dataHandler: dataHandler,
                                                  completionHandler: completionHandler)
        }
    }

    private func checkForSpotifyPlaylistPagnation(nextPage: String?,
                                                  dataHandler: @escaping (SongInformation) -> Void,
                                                  completionHandler: @escaping () -> Void) {
        guard let nextPage = nextPage else { completionHandler(); return }
        spotifyManager.get(SpotifyPlaylist.Tracks.self, url: nextPage) { (pagingObject) in
            for item in pagingObject.items ?? [] {
                let songInfo = SongInformation(name: item.track.name,
                                               artist: item.track.artist.name,
                                               album: item.track.album?.name ?? "")
                dataHandler(songInfo)
            }
            self.checkForSpotifyPlaylistPagnation(nextPage: pagingObject.next,
                                                  dataHandler: dataHandler,
                                                  completionHandler: completionHandler)
        }
    }

    func findSongs(songs: [SongInformation],
                   dataHandler: @escaping (Int, SongProgress) -> Void,
                   completionHandler: @escaping () -> Void) {
        for _ in songs {
            self.songResponse.append([])
            self.toAddSongs.append(nil)
            group.enter()
        }
        switch toService {
        case .appleMusic:
            DispatchQueue.global().async {
                self.findSongsOnAppleMusic(songs: songs, dataHandler: dataHandler)
            }
        case .spotify:
            DispatchQueue.global().async {
                self.findSongsOnSpotify(songs: songs, dataHandler: dataHandler)
            }
        }
        group.notify(queue: .main, execute: {
            self.readyToCreatePlaylist = true
            completionHandler()
        })

    }

    private func findSongsOnSpotify(songs: [SongInformation],
                                    dataHandler: @escaping (Int, SongProgress) -> Void) {
        for index in 0..<songs.count {
            let songInfo = songs[index]
            let cleanedTitle = songInfo.name.replacingOccurrences(of: "\\([^()]*\\)",
                                                                  with: "",
                                                                  options: [.regularExpression])
            let searchTerm = (cleanedTitle + " " + songInfo.artist)
                .replacingOccurrences(of: "&", with: "and")
                .replacingOccurrences(of: "?", with: "")
                .folding(options: .diacriticInsensitive, locale: nil)
                .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            spotifyManager.find(SpotifyTrack.self, searchTerm) { (tracks) in
                self.group.leave()
                guard let tracks = tracks else {
                    print("WARNING: Spotify can't find \(songInfo.name)")
                    dataHandler(index, .notFound)
                    return
                }
                guard !tracks.isEmpty else {
                    print("WARNING: Spotify can't find \(songInfo.name)")
                    dataHandler(index, .notFound)
                    return
                }
                var possibleSongs: [Song] = []
                for track in tracks {
                    possibleSongs.append(Song(name: track.name,
                                              artist: track.artist.name,
                                              album: track.album?.name ?? "",
                                              value: SongValue.spotifyTrack(track)))
                    if  self.toAddSongs[index] == nil
                        && track.artist.name.isEqualStrippedString(songInfo.artist)
                        && track.name.isPartialMatch(songInfo.name) {
                        self.toAddSongs[index] = .spotifyTrack(track)
                    }
                }
                self.songResponse[index] = possibleSongs
                if self.toAddSongs[index] == nil {
                    dataHandler(index, .songsFound)
                } else {
                    dataHandler(index, .matchFound)
                }
            }
        }
    }

    private func findSongsOnAppleMusic(songs: [SongInformation],
                                       dataHandler: @escaping (Int, SongProgress) -> Void) {
        for index in 0..<songs.count {
            if stopRequests { break }
            let songInfo = songs[index]
            do {
                sleep(3) // simply because of itunes rate limiting
            }
            sendiTunesSongRequest(songName: songInfo.name, artistName: songInfo.artist) { (songRequest) in
                self.group.leave()
                guard let songRequest = songRequest else {
                    dataHandler(index, .notFound)
                    return
                }
                guard !songRequest.results.isEmpty else {
                    dataHandler(index, .notFound)
                    return
                }
                var possibleSongs: [Song] = []
                for song in songRequest.results {
                    possibleSongs.append(song.toSong)
                    if self.toAddSongs[index] == nil
                        && songInfo.name.isEqualStrippedString(song.trackName)
                        && songInfo.artist.isPartialMatch(song.artistName) {
                        self.toAddSongs[index] = .appleId("\(song.trackId)")
                    }
                }
                self.songResponse[index] = possibleSongs
                if self.toAddSongs[index] == nil {
                    dataHandler(index, .songsFound)
                } else {
                    dataHandler(index, .matchFound)
                }
            }
        }
    }

    public func createPlaylist(dataHandler: @escaping (String, Bool) -> Void,
                               completionHandler: @escaping (Bool) -> Void) {
        switch toService {
        case .appleMusic:
            createAppleMusicPlaylist(dataHandler: dataHandler, completionHandler: completionHandler)
        case .spotify:
            createSpotifyPlaylist(dataHandler: dataHandler, completionHandler: completionHandler)
        }
    }

    private func createAppleMusicPlaylist(dataHandler: @escaping (String, Bool) -> Void,
                                          completionHandler: @escaping (Bool) -> Void) {
        let playlistUUID = UUID()
        let playlistMetadata = MPMediaPlaylistCreationMetadata(name: newPlaylistName)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy h:mm a"
        playlistMetadata.descriptionText = """
        This playlist was added via the Twister app. This playlist was entitled \
        '\(playlistName)' from \(fromService.rawValue). \
        Twisted on \(dateFormatter.string(from: Date()))
        """
        group.enter() // A
        MPMediaLibrary.default().getPlaylist(with: playlistUUID, creationMetadata: playlistMetadata) { (playlist, error)
            in
            guard error == nil else {
                print("Playlist could not be created")
                //self.group.leave() // A
                completionHandler(false)
                return
            }
            guard let playlist = playlist else { return }
            let serialQueue = DispatchQueue(label: "createAppleMusicPlaylist")
            for songValue in self.toAddSongs.compactMap({ $0 }) {
                self.group.enter() // B
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
                        self.group.leave() // B
                        if error != nil {
                            print("ERROR: Could not add \(songId) to the playlist!")
                            dataHandler(self.getNameFromId(songValue), false)
                        } else {
                            dataHandler(self.getNameFromId(songValue), true)
                        }
                        NotificationCenter.default.post(name: MediaLibraryManager.libraryDidUpdate, object: nil)
                    }
                }
            }
            self.group.leave() // A
        }
        group.notify(queue: .main) {
            NotificationCenter.default.post(name: MediaLibraryManager.libraryDidUpdate, object: nil)
            completionHandler(true)
        }
    }

    private func createSpotifyPlaylist(dataHandler: @escaping (String, Bool) -> Void,
                                       completionHandler: @escaping (Bool) -> Void) {
        group.enter() // C
        spotifyManager.createPlaylist(playlistName: newPlaylistName) { (playlistId) in
            guard let playlistId = playlistId else {
                print("Playlist could not be made")
                completionHandler(false)
                //self.group.leave() // C
                return
            }
            self.group.enter() // D
            let tracks = self.toAddSongs.map { (songVal) -> SpotifyTrack? in
                switch songVal {
                case .spotifyTrack(let track):
                    return track
                default:
                    return nil
                }
            }
            spotifyManager.addSongsToPlaylist(playlistId: playlistId, tracks: tracks.compactMap { $0 }) { (success) in
                self.group.leave() // D
                if !success {
                    print("ERROR: Addings tracks to spotify")
                    dataHandler("All Songs", false)
                } else {
                    dataHandler("All Songs", true)
                }
            }
            self.group.leave() // C
        }
        group.notify(queue: .main) {
            completionHandler(true)
        }
    }

    private func getNameFromId(_ song: SongValue) -> String {
        for index in 0..<toAddSongs.count {
            for index2 in 0..<songResponse[index].count
            where song == songResponse[index][index2].value {
                return songResponse[index][index2].name
            }
        }
        return ""
    }
}
