//
//  iTunesRequests.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 3/31/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

//will search for a songId given the song name and artist name
func sendiTunesRequest(songName: String, artistName: String, completionHandler: @escaping ((String?, [[String:Any]])->Void)) {
    let searchTerm = (songName + " " + artistName)
    let urlQueries = [URLQueryItem(name: "media", value: "music"),
                      URLQueryItem(name: "entity", value: "song"),
                      URLQueryItem(name: "term", value: searchTerm), //search by song name
                      URLQueryItem(name: "limit", value: "20")
                    ]
    var u = URLComponents(string: "https://itunes.apple.com/search")!
    u.queryItems = urlQueries
    let task = URLSession.shared.dataTask(with: u.url!) { (data, response, error) in
        //print(response.debugDescription)
        guard let data = data else { return }
        print(String(data: data, encoding: .utf8))
        if let fetchedDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
            let fetchedArray = fetchedDict["results"] as? [[String:Any]] {
            for dict in fetchedArray {
                if let artist = dict ["artistName"] as? String {
                    if (artist.lowercased() == artistName.lowercased()) { //check the artist
                        if let trackId = dict["trackId"] as? Int {
                            let str = String(describing: trackId)
                            completionHandler(str, fetchedArray)
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

func sendiTunesSongRequest(songName: String, artistName: String, completionHandler: @escaping (((iTunesSongRequest?) -> Void))) {
    let searchTerm = (songName + " " + artistName)
    let urlQueries = [URLQueryItem(name: "media", value: "music"),
                      URLQueryItem(name: "entity", value: "song"),
                      URLQueryItem(name: "term", value: searchTerm), //search by song name
                      URLQueryItem(name: "limit", value: "20")
                    ]
    var u = URLComponents(string: "https://itunes.apple.com/search")!
    u.queryItems = urlQueries
    let task = URLSession.shared.dataTask(with: u.url!) { (data, response, error) in
        guard let data = data else { completionHandler(nil); return }
        do {
            let results = try JSONDecoder().decode(iTunesSongRequest.self, from: data)
            completionHandler(results)
        } catch {
            completionHandler(nil)
            print(error)
        }
    }
    task.resume()
}

public struct iTunesSongRequest: Decodable {
    var results: [iTunesTracks]
    var resultCount: Int
    
    public struct iTunesTracks: Decodable {
        var trackId: Int
        var artistId: Int
        var collectionId: Int
        
        var artistName: String
        var collectionName: String
        var trackName: String
        
        var previewUrl: String? //url to m4a link
        
        var artworkUrl30: String?
        var artworkUrl60: String?
        var artworkUrl100: String?
        
        var toSong: Song {
            return Song(name: trackName, artist: artistName, album: collectionName, value: .appleId("\(trackId)"))
        }
    }
    
    
}
