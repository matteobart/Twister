//
//  MainModel.swift
//  Twister
//
//  Created by Matteo Bart on 4/22/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import MediaPlayer
import SpotifyKit

class MainModel {
    var allPlaylists: [[(playlistName: String, playlistId: String)]]
    var appleMusicPlaylists: [(playlistName: String, playlistId: String)] {
        return allPlaylists[0]
    }
    var spotifyPlaylists: [(playlistName: String, playlistId: String)] {
        return allPlaylists[1]
    }

    init() {
        allPlaylists = [ [], [] ]
    }

    func servicesAuthenticated() -> Bool {
        return spotifyManager.hasToken && authorizationManager.isAuthenticated()
    }

    func getAppleMusicPlaylists(dataHandler: @escaping ([(playlistName: String, playlistId: String)]) -> Void) {
        if !appleMusicPlaylists.isEmpty {
            dataHandler(appleMusicPlaylists)
            return
        }
        // make the request
        let myPlaylistQuery = MPMediaQuery.playlists()
        guard let playlists = myPlaylistQuery.collections else { return }
        for playlist in playlists {
            guard let playlistName = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String else {
                continue
            }
            let playlistUUID = String(describing: playlist.value(forProperty: MPMediaPlaylistPropertyPersistentID)!)
            let tuple = (playlistName: playlistName, playlistId: playlistUUID)
            allPlaylists[0].append(tuple)
        }
        dataHandler(appleMusicPlaylists)

    }

    func getSpotifyPlaylists(dataHandler: @escaping ([(playlistName: String, playlistId: String)]) -> Void) {
        if !spotifyPlaylists.isEmpty {
            dataHandler(spotifyPlaylists)
            return
        }
        // make the request
        spotifyManager.library(SpotifyPlaylist.self) { (libraryItems, response) in
            for item in libraryItems {
                let tuple = (playlistName: item.name, playlistId: item.id ?? "")
                self.allPlaylists[1].append(tuple)
            }
            self.checkForMoreSpotifyPlaylists(nextPage: response.next, dataHandler: dataHandler)
        }
    }

    private func checkForMoreSpotifyPlaylists(nextPage: String?,
                                              dataHandler:
                                                    @escaping ([(playlistName: String, playlistId: String)]) -> Void) {
        guard let nextPage = nextPage else {
            dataHandler(spotifyPlaylists)
            return
        }
        spotifyManager.get(SpotifyLibraryResponse<SpotifyPlaylist>.self, url: nextPage) { (pagingObject) in
            for item in pagingObject.items ?? [] {
                let tuple = (playlistName: item.name, playlistId: item.id ?? "")
                self.allPlaylists[1].append(tuple)
            }
            self.checkForMoreSpotifyPlaylists(nextPage: pagingObject.nextURL, dataHandler: dataHandler)
        }
    }
}
