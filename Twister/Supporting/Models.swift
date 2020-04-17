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

extension String {
    /**
            Checks if two strings are the same if lowercased and removed all non-alphanumeric character
     */
    func isEqualStrippedString(_ to: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "[^A-Za-z0-9]", options: [])
        let toRange = NSMakeRange(0, to.count)
        let toModString = regex.stringByReplacingMatches(in: to, options: [], range: toRange, withTemplate: "").lowercased()
        let selfRange = NSMakeRange(0, self.count)
        let selfModString = regex.stringByReplacingMatches(in: self, options: [], range: selfRange, withTemplate: "").lowercased()
        return selfModString == toModString
    }
    
    func containsStrippedString(_ to: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "[^A-Za-z0-9]", options: [])
        let toRange = NSMakeRange(0, to.count)
        let toModString = regex.stringByReplacingMatches(in: to, options: [], range: toRange, withTemplate: "").lowercased()
        let selfRange = NSMakeRange(0, self.count)
        let selfModString = regex.stringByReplacingMatches(in: self, options: [], range: selfRange, withTemplate: "").lowercased()
        return selfModString.contains(toModString)
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
