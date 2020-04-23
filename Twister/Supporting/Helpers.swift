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

enum SongProgress {
    case processing
    case matchFound
    case songsFound
    case notFound
}

struct SongInformation {
    var name: String
    var artist: String
    var album: String
}

struct Song {
    var name: String {
        return information.name
    }
    var artist: String {
        return information.artist
    }
    var album: String {
        return information.album
    }
    var value: SongValue
    var information: SongInformation
    init(name: String, artist: String, album: String, value: SongValue) {
        self.information = SongInformation(name: name, artist: artist, album: album)
        self.value = value
    }
}

extension String {
    /**
                Returns a stripped version of the string
                Stripped: only alphanumeric (no spaces, symbols) and lowercased
                    
     */
    func strip() -> String {
        do {
            let regex = try NSRegularExpression(pattern: "[^A-Za-z0-9]", options: [])
            let toRange = NSRange(location: 0, length: self.count)
            return regex.stringByReplacingMatches(in: self,
                                                  options: [],
                                                  range: toRange,
                                                  withTemplate: "").lowercased()
        } catch {
            print(error)
            return self
        }
    }
     /**
            Checks if two strings are the same if lowercased and removed all non-alphanumeric character
     */
    func isEqualStrippedString(_ other: String) -> Bool {
        return self.strip() == other.strip()
    }
    func containsStrippedString(_ other: String) -> Bool {
        return self.strip().contains(other.strip())
    }
    func isPartialMatch(_ with: String) -> Bool {
        return self.containsStrippedString(with) || with.containsStrippedString(self)
    }
}

extension UITableView {
    func unselectSelected() {
        if self.indexPathForSelectedRow != nil {
            self.deselectRow(at: self.indexPathForSelectedRow!, animated: true)
        }
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
