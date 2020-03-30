//
//  Helper.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import SpotifyKit

enum StreamingService: String, CaseIterable {
    case spotify
    case appleMusic
}

enum SongValue {
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

//will search for a songId given the song name and artist name
func sendiTunesRequest(songName: String, artistName: String, completionHandler: @escaping ((String?, [[String:Any]])->Void)) {
    let urlQueries = [URLQueryItem(name: "media", value: "music"),
                      URLQueryItem(name: "entity", value: "song"),
                      URLQueryItem(name: "term", value: songName), //search by song name
                      URLQueryItem(name: "limit", value: "20")
                    ]
    var u = URLComponents(string: "https://itunes.apple.com/search")!
    u.queryItems = urlQueries
    let task = URLSession.shared.dataTask(with: u.url!) { (data, response, error) in
        //print(response.debugDescription)
        guard let data = data else { return }
        if let fetchedDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
            let fetchedArray = fetchedDict!["results"] as? [[String:Any]] {
            for dict in fetchedArray {
                if let artist = dict ["artistName"] as? String {
                    if (artist == artistName) { //check the artist
                        if let trackId = dict["trackId"] as? Int {
                            let str = String(describing: trackId)
                            completionHandler(str, fetchedArray);
                            return
                        }
                    }
                }
            }
            completionHandler(nil, fetchedArray); return
        } else { completionHandler(nil, []); return }
    }
    
    task.resume()
    
}
