//
//  Helper.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import SpotifyKit

let appTint = UIColor(red: 62/255, green: 140/255, blue: 247/255, alpha: 1)

enum StreamingService: String, CaseIterable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
}

enum SongValue: Equatable {
    static func == (lhs: SongValue, rhs: SongValue) -> Bool {
        switch (lhs, rhs) {
        case let (.appleId(lid), .appleId(rid)): return lid == rid
        case let (.spotifyTrack(lTrack), .spotifyTrack(rTrack)): return lTrack.id == rTrack.id
        default: return false
        }
    }
    
    case appleId(String)
    case spotifyTrack(SpotifyTrack)
}

struct Song {
    var name: String
    var artist: String
    var album: String
    var value: SongValue
    init(name: String, artist: String, album: String, value: SongValue) {
        self.name = name
        self.artist = artist
        self.album = album
        self.value = value
    }
}

class Counter {
    private var queue = DispatchQueue(label: "your.queue.identifier")
    private (set) var value: Int = 0

    func increment() {
        queue.sync {
            value += 1
        }
    }
}
