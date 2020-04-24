//
//  SpotifyKit.swift
//  SpotifyKit
//
//  Created by Marco Albera on 30/01/17.
//
//

#if !os(OSX)
    import UIKit
#else
    import AppKit
#endif

// MARK: Token saving options

enum TokenSavingMethod {
    case preference
}

// MARK: Spotify queries addresses

/**
 Parameter names for Spotify HTTP requests
 */
private struct SpotifyParameter {
    // Search
    static let name = "q"
    static let type = "type"
    // Authorization
    static let clientId     = "client_id"
    static let responseType = "response_type"
    static let redirectUri  = "redirect_uri"
    static let scope        = "scope"
    // Token
    static let clientSecret = "client_secret"
    static let grantType    = "grant_type"
    static let code         = "code"
    static let refreshToken = "refresh_token"
    // User's library
    static let ids          = "ids"
    static let playlistName = "name"
}

/**
 Header names for Spotify HTTP requests
 */
private struct SpotifyHeader {
    // Authorization
    static let authorization = "Authorization"
}

// MARK: Queries data types

/**
 URLs for Spotify HTTP queries
 */
private enum SpotifyQuery: String, URLConvertible {
    var url: URL? {
        switch self {
        case .master, .account:
            return URL(string: self.rawValue)
        case .search, .users, .me, .contains:
            return URL(string: SpotifyQuery.master.rawValue + self.rawValue)
        case .authorize, .token:
            return URL(string: SpotifyQuery.account.rawValue + self.rawValue)
        }
    }
    // Master URLs
    case master  = "https://api.spotify.com/v1/"
    case account = "https://accounts.spotify.com/"
    // Search
    case search    = "search"
    case users     = "users"
    // Authentication
    case authorize = "authorize"
    case token     = "api/token"
    // User's library
    case me        = "me/"
    case contains  = "me/tracks/contains"
    static func libraryUrlFor<T>(_ what: T.Type) -> URL? where T: SpotifyLibraryItem {
        return URL(string: master.rawValue + me.rawValue + what.type.searchKey.rawValue + "?limit=50")
    }
    static func urlForNewPlaylist(userId: String) -> URL? {
        let str = master.rawValue + users.rawValue + "/" + userId + "/" +  SpotifyPlaylist.type.searchKey.rawValue
        return URL.init(string: str)
    }
    static func urlFor<T>(_ what: T.Type,
                          id: String) -> URL? where T: SpotifySearchItem {
        switch what.type {
        case .track, .album, .artist, .playlist:
            return URL(string: master.rawValue + what.type.searchKey.rawValue + "/\(id)")
        case .user:
            return URL(string: master.rawValue + users.rawValue + "/\(id)")!
        }
    }
}

/**
 Scopes (aka permissions) required by our app
 during authorization phase
*/
// Read more about them here: https://developer.spotify.com/documentation/general/guides/scope
public enum SpotifyScope: String {
    case imageUpload =              "ugc-image-upload"
    case readPlaybackState =        "user-read-playback-state"
    case modifyPlaybackState =      "user-modify-playback-state"
    case readCurrentlyPlaying =     "user-read-currently-playing"
    case streaming =                "streaming"
    case remoteControl =            "app-remote-control"
    case readEmail =                "user-read-email"
    case readPrivate =              "user-read-private"
    case readCollabPlaylists =      "playlist-read-collaborative"
    case modifyPublicPlaylists =    "playlist-modify-public"
    case readPrivatePlaylists =     "playlist-read-private"
    case modifyPrivatePlaylists =   "playlist-modify-private"
    case modifyLibrary =            "user-library-modify"
    case readLibrary =              "user-library-read"
    case readTop =                  "user-top-read"
    case readPlaybackPosition =     "user-read-playback-position"
    case readRecentlyPlayed =       "user-read-recently-played"
    case readFollow =               "user-follow-read"
    case modifyFollow =             "user-follow-modify"
    /**
     Creates a string to pass as parameter value
     with desired scope keys
     */
    static func string(with scopes: [SpotifyScope]) -> String {
        return String(scopes.reduce("") { "\($0) \($1.rawValue)" }.dropFirst())
    }
}

private enum SpotifyAuthorizationResponseType: String {
    // swiftlint:disable:next redundant_string_enum_value
    case code = "code"
}

private enum SpotifyAuthorizationType: String {
    case basic  = "Basic "
    case bearer = "Bearer "
}

/**
 Spotify authentication grant types for obtaining token
 */
private enum SpotifyTokenGrantType: String {
    case authorizationCode = "authorization_code"
    case refreshToken      = "refresh_token"
}

// MARK: Helper class
@objc(SpotifyKit)private class SpotifyToken: NSObject, Decodable, NSCoding {
    var accessToken: String
    var expiresIn: Int
    var refreshToken: String
    var tokenType: String
    var saveTime: TimeInterval
    static let preferenceKey = "spotifyKitToken"
    // MARK: Decodable
    enum Key: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case saveTime = "save_time"
    }
    convenience required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        self.init(
            accessToken: try? container.decode(String.self, forKey: .accessToken),
            expiresIn: try? container.decode(Int.self, forKey: .expiresIn),
            refreshToken: try? container.decode(String.self, forKey: .refreshToken),
            tokenType: try? container.decode(String.self, forKey: .tokenType)
        )
    }
    // MARK: NSCoding
    func encode(with coder: NSCoder) {
        coder.encode(accessToken, forKey: Key.accessToken.stringValue)
        coder.encode(expiresIn, forKey: Key.expiresIn.stringValue)
        coder.encode(refreshToken, forKey: Key.refreshToken.stringValue)
        coder.encode(tokenType, forKey: Key.tokenType.stringValue)
        coder.encode(saveTime, forKey: Key.saveTime.stringValue)
    }
    required convenience init?(coder decoder: NSCoder) {
        self.init(
            accessToken: decoder.decodeObject(forKey: Key.accessToken.stringValue) as? String,
            expiresIn: decoder.decodeInteger(forKey: Key.expiresIn.stringValue),
            refreshToken: decoder.decodeObject(forKey: Key.refreshToken.stringValue) as? String,
            tokenType: decoder.decodeObject(forKey: Key.tokenType.stringValue) as? String,
            saveTime: decoder.decodeDouble(forKey: Key.saveTime.stringValue)
        )
    }
    // MARK: Other
    required init(accessToken: String?,
                  expiresIn: Int?,
                  refreshToken: String?,
                  tokenType: String?,
                  saveTime: TimeInterval? = nil) {
        self.accessToken  = accessToken ?? ""
        self.expiresIn    = expiresIn ?? 0
        self.refreshToken = refreshToken ?? ""
        self.tokenType    = tokenType ?? ""
        self.saveTime     = saveTime ?? Date.timeIntervalSinceReferenceDate
    }
    /**
     Writes the contents of the token to a preference.
     */
    func writeToKeychain() {
        Keychain.standard.set(self, forKey: SpotifyToken.preferenceKey)
    }
    /**
     Loads the token object from a preference.
     */
    static func loadFromKeychain() -> SpotifyToken? {
        return Keychain.standard.value(forKey: SpotifyToken.preferenceKey) as? SpotifyToken
    }
    /**
     Deletes the token object from a preference
     */
    static func deleteFromKeychain() {
        Keychain.standard.delete(objectWithKey: SpotifyToken.preferenceKey)
    }
    /**
     Updates a token from a JSON, for instance after calling 'refreshToken',
     when only a new 'accessToken' is provided
     */
    func refresh(from data: Data) {
        guard let token = try? JSONDecoder().decode(SpotifyToken.self,
                                                    from: data) else { return }
        accessToken = token.accessToken
        saveTime    = Date.timeIntervalSinceReferenceDate
    }
    /**
     Returns whether a token is expired basing on saving time,
     current time and provided duration limit
     */
    var isExpired: Bool {
        return Date.timeIntervalSinceReferenceDate - saveTime > Double(expiresIn)
    }
    /**
     Returns true if the token is valid (aka not blank)
     */
    var isValid: Bool {
        return !self.accessToken.isEmpty
            && !self.refreshToken.isEmpty
            && !self.tokenType.isEmpty
            && self.expiresIn != 0
    }
    var details: NSString {
        return  """
        Access token:  \(accessToken)
        Expires in:    \(expiresIn)
        Refresh token: \(refreshToken)
        Token type:    \(tokenType)
        """ as NSString
    }
}

public class SpotifyManager {
    public struct SpotifyDeveloperApplication {
        var clientId: String
        var clientSecret: String
        var redirectUri: String
        public init(clientId: String,
                    clientSecret: String,
                    redirectUri: String) {
            self.clientId     = clientId
            self.clientSecret = clientSecret
            self.redirectUri  = redirectUri
        }
    }
    private var application: SpotifyDeveloperApplication?
    private var tokenSavingMethod: TokenSavingMethod = .preference
    private var applicationJsonURL: URL?
    private var token: SpotifyToken?
    private var tokenJsonURL: URL?
    // MARK: Constructors
    public init(with application: SpotifyDeveloperApplication) {
        self.application = application
        if let token = SpotifyToken.loadFromKeychain() {
            self.token = token
        }
    }
    // MARK: Query functions
    private func tokenQuery(operation: @escaping (SpotifyToken) -> Void) {
        guard let token = self.token else { return }
        guard !token.isExpired else {
            // If the token is expired, refresh it first
            // Then try repeating the operation
            refreshToken { refreshed in
                if refreshed {
                    operation(token)
                }
            }
            return
        }
        // Run the requested query operation
        operation(token)
    }

    /**
     Gets a specific Spotify item (track, album, artist or playlist
     - parameter what: the type of the item ('SpotifyTrack', 'SpotifyAlbum'...)
     - parameter id: the item Spotify identifier
     - parameter playlistUserId: the id of the user who owns the requested playlist
     - parameter completionHandler: the block to run when result is found and passed as parameter to it
     */
    public func get<T>(_ what: T.Type,
                       id: String,
                       completionHandler: @escaping ((T) -> Void)) where T: SpotifySearchItem {
        tokenQuery { token in
            URLSession.shared.request(SpotifyQuery.urlFor(what, id: id),
                                      method: .GET,
                                      headers: self.authorizationHeader(with: token)) { result in
                if  case let .success(data) = result {
                    do {
                        let result = try JSONDecoder().decode(what,
                                                              from: data)
                            completionHandler(result)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    public func get<T>(_ what: T.Type,
                       url: String,
                       completionHandler: @escaping ((T) -> Void)) where T: SpotifyPagingObject {
        tokenQuery { token in
            URLSession.shared.request(url,
                                      method: .GET,
                                      headers: self.authorizationHeader(with: token)) { result in
                if  case let .success(data) = result {
                    do {
                        let result = try JSONDecoder().decode(what,
                                                              from: data)
                            completionHandler(result)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    /**
     Finds items on Spotify that match a provided keyword
     - parameter what: the type of the item ('SpotifyTrack', 'SpotifyAlbum'...)
     - parameter keyword: the item name
     - parameter completionHandler: the block to run when results
     are found and passed as parameter to it
     */
    public func find<T>(_ what: T.Type,
                        _ keyword: String,
                        completionHandler: @escaping ([T]?) -> Void) where T: SpotifySearchItem {
        tokenQuery { token in
            URLSession.shared.request(SpotifyQuery.search,
                                      method: .GET,
                                      parameters: self.searchParameters(for: what.type, keyword),
                                      headers: self.authorizationHeader(with: token)) { result in
                if  case let .success(data) = result,
                    let results = try? JSONDecoder().decode(SpotifyFindResponse<T>.self,
                                                           from: data).results.items {
                    completionHandler(results)
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    /**
     Finds the first track on Spotify matching search results for
     - parameter title: the title of the track
     - parameter artist: the artist of the track
     - parameter completionHandler: the handler that is executed with the track as parameter
     */
    public func getTrack(title: String,
                         artist: String,
                         completionHandler: @escaping (SpotifyTrack?) -> Void) {
        find(SpotifyTrack.self,
             "\(title) \(artist)"
                .folding(options: .diacriticInsensitive, locale: nil)
                .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) { results in
            if let track = results?.first {
                completionHandler(track)
            } else {
                completionHandler(nil)
            }
        }
    }
    /**
     Gets the curernt Spotify user's profile
     - parameter completionHandler: the handler that is executed with the user as parameter
     */
    public func myProfile(completionHandler: @escaping (SpotifyUser) -> Void) {
        tokenQuery { token in
            URLSession.shared.request(SpotifyQuery.me,
                                      method: .GET,
                                      headers: self.authorizationHeader(with: token)) { result in
                if  case let .success(data) = result,
                    let result = try? JSONDecoder().decode(SpotifyUser.self,
                                                           from: data) {
                    completionHandler(result)
                }
            }
        }
    }
    // MARK: Authorization
    /**
     Retrieves the authorization code with user interaction
     Note: this only opens the browser window with the proper request,
     you then have to manually copy the 'code' from the opened url
     and insert it to get the actual token
     */
    public func authorize() {
        // Only proceed with authorization if we have no token
        authorize(with: [.readPrivate, .readEmail, .modifyLibrary, .readLibrary, .readCollabPlaylists,
                         .readPrivatePlaylists, .modifyPublicPlaylists, .modifyPrivatePlaylists])

    }
    public func authorize(with scopes: [SpotifyScope]) {
        // Only proceed with authorization if we have no token
        guard !hasToken else { return }
        if  let application = application,
            let url = SpotifyQuery.authorize.url?.with(parameters:
                                                        authorizationParameters(for: application, with: scopes)) {
            print(url)
            #if os(OSX)
                #if swift(>=4.0)
                    NSWorkspace.shared.open(url)
                #else
                    NSWorkspace.shared().open(url)
                #endif
            #else
                UIApplication.shared.open(url)
            #endif
        }
    }
    /**
     Removes the saved authorization token from the keychain
     */
    public func deauthorize() {
        // Only proceed with deauthorization if we have a token
        guard hasToken else { return }
        SpotifyToken.deleteFromKeychain()
        // Reset the token
        token = nil
    }
    /**
     Retrieves the authorization code after the authentication process has succeded
     and completes token saving.
     - parameter url: the URL with code sent by Spotify after authentication success
     */
    public func saveToken(from url: URL, completionHandler: @escaping (() -> Void)) {
        if  let urlComponents = URLComponents(string: url.absoluteString),
            let queryItems    = urlComponents.queryItems {
            // Get "code=" parameter from URL
            let code = queryItems.filter { item in item.name == "code" } .first?.value!
            // Send code to SpotifyKit
            if let authorizationCode = code {
                saveToken(from: authorizationCode, completionHandler: completionHandler)
            }
        }
    }
    /**
     Retrieves the token from the authorization code and saves it locally
     - parameter authorizationCode: the code received from Spotify redirected uri
     */
    public func saveToken(from authorizationCode: String, completionHandler: @escaping (() -> Void)) {
        guard let application = application else { return }
        URLSession.shared.request(SpotifyQuery.token,
                                  method: .POST,
                                  parameters: tokenParameters(for: application,
                                                              from: authorizationCode)) { result in
            if case let .success(data) = result {
                self.token = self.generateToken(from: data)
                // Prints the token for debug
                if let token = self.token {
                    debugPrint(token.details)
                    switch self.tokenSavingMethod {
                    case .preference:
                        token.writeToKeychain()
                    }
                    completionHandler()
                }
            }
        }
    }
    /**
     Generates a token from values provided by the user
     - parameters: the token data
     */
    public func saveToken(accessToken: String,
                          expiresIn: Int,
                          refreshToken: String,
                          tokenType: String) {
        self.token = SpotifyToken(accessToken: accessToken,
                                  expiresIn: expiresIn,
                                  refreshToken: refreshToken,
                                  tokenType: tokenType)
        // Prints the token for debug
        if let token = self.token { debugPrint(token.details) }
    }
    /**
     Returns if the helper is currently holding a token
     */
    public var hasToken: Bool {
        guard let token = token else { return false }
        // Only return true if the token is actually valid
        return token.isValid
    }
    /**
     Refreshes the token when expired
     */
    public func refreshToken(completionHandler: @escaping (Bool) -> Void) {
        guard let application = application, let token = self.token else { return }
        URLSession.shared.request(SpotifyQuery.token,
                                  method: .POST,
                                  parameters: refreshTokenParameters(from: token),
                                  headers: refreshTokenHeaders(for: application)) { result in
            if case let .success(data) = result {
                // Refresh current token
                // Only 'accessToken' needs to be changed
                // guard is not really needed here because we checked before
                self.token?.refresh(from: data)
                // Prints the token for debug
                if let token = self.token {
                    debugPrint(token.details)
                    // Run completion handler
                    // only after the token has been saved
                    completionHandler(true)
                }
            } else {
                completionHandler(false)
            }
        }
    }
    // MARK: User library interaction
    /**
     Gets the first saved tracks/albums/playlists in user's library
     - parameter type: .track, .album or .playlist
     - parameter completionHandler: the callback to run, passes the tracks array
     as argument
    */
    public func library<T>(_ what: T.Type,
                           completionHandler: @escaping ([T], SpotifyLibraryResponse<T>) -> Void)
                           where T: SpotifyLibraryItem {
        tokenQuery { token in
            URLSession.shared.request(SpotifyQuery.libraryUrlFor(what),
                                      method: .GET,
                                      headers: self.authorizationHeader(with: token)) { result in
                if  case let .success(data) = result {
                    do {
                        let results = try JSONDecoder().decode(SpotifyLibraryResponse<T>.self,
                            from: data)
                        completionHandler(results.items ?? [], results)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    /**
     Saves a track to user's "Your Music" library
     - parameter trackId: the id of the track to save
     - parameter completionHandler: the callback to execute after response,
     brings the saving success as parameter
     */
    public func save(trackId: String,
                     completionHandler: @escaping (Bool) -> Void) {
        tokenQuery { token in
            URLSession.shared.request(SpotifyQuery.libraryUrlFor(SpotifyTrack.self),
                                      method: .PUT,
                                      parameters: self.trackIdsParameters(for: trackId),
                                      headers: self.authorizationHeader(with: token)) { result in
                if case .success(_) = result {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            }
        }
    }
    public func createPlaylist(playlistName: String,
                               description: String,
                               completionHandler: @escaping (String?) -> Void) {
        tokenQuery { (token) in
            self.myProfile { (user) in
                guard let id = user.id else { return }
                self.createPlaylistRequest(playlistName: playlistName,
                                           description: description,
                                           userName: id,
                                           token: token.accessToken,
                                           completionHandler: completionHandler)
            }
        }
    }
    func createPlaylistRequest(playlistName: String,
                               description: String,
                               userName: String,
                               token: String,
                               completionHandler: @escaping (String?) -> Void) {
        let body = NewSpotifyPlaylist(name: playlistName,
                                      isPublic: false,
                                      collaborative: false,
                                      description: description)
        let postData = try! JSONEncoder().encode(body)

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/users/"+userName+"/playlists")!,
                                 timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")

        request.httpMethod = "POST"
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if error != nil || data == nil {
                completionHandler(nil)
            } else {
                print(String(data: data!, encoding: .utf8)!)
                guard let playlist = try? JSONDecoder().decode(SpotifyPlaylist.self, from: data!) else {
                    completionHandler(nil)
                    return
                }
                completionHandler(playlist.id)
            }
        }
        task.resume()
    }

    // recursive function, as tracks are only processed 100 at a time
    public func addSongsToPlaylist(playlistId: String,
                                   tracks: [SpotifyTrack],
                                   completionHandler: @escaping (Bool) -> Void) {
        tokenQuery { (token) in
            //TODO: Limit to 100 songs at a time
            let trackToAdd = Array(tracks[0..<min(100, tracks.count)]) //100 at a time
            let leftoverTracks = Array(tracks[min(100, tracks.count)..<tracks.count])
            let body = AddPlaylistSongs(tracks: tracks)
            let postData = try! JSONEncoder().encode(body)
            var request = URLRequest(url:
                            URL(string: "https://api.spotify.com/v1/playlists/"+playlistId+"/tracks")!,
                                timeoutInterval: Double.infinity)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + token.accessToken, forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            request.httpBody = postData
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                if error != nil || data == nil {
                    print(error!)
                    completionHandler(false)
                } else {
                    //print(String(data: data!, encoding: .utf8)!)
                    if !trackToAdd.isEmpty { // if more to process
                        self.addSongsToPlaylist(playlistId: playlistId,
                                                tracks: leftoverTracks,
                                                completionHandler: completionHandler)

                    } else {
                        completionHandler(true)
                    }
                }
            }
            task.resume()
        }
    }
    /**
     Saves a track to user's "Your Music" library
     - parameter track: the 'SpotifyTrack' object to save
     - parameter completionHandler: the callback to execute after response,
     brings the saving success as parameter
     */
    public func save(track: SpotifyTrack,
                     completionHandler: @escaping (Bool) -> Void) {
        guard let trackId = track.id else { return }
        save(trackId: trackId, completionHandler: completionHandler)
    }
    /**
     Deletes a track from user's "Your Music" library
     - parameter trackId: the id of the track to save
     - parameter completionHandler: the callback to execute after response,
     brings the deletion success as parameter
     */
    public func delete(trackId: String,
                       completionHandler: @escaping (Bool) -> Void) {
        tokenQuery { token in
            URLSession.shared.request(SpotifyQuery.libraryUrlFor(SpotifyTrack.self),
                                      method: .DELETE,
                                      parameters: self.trackIdsParameters(for: trackId),
                                      headers: self.authorizationHeader(with: token)) { result in
                if case .success(_) = result {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            }
        }
    }
    /**
     Deletes a track from user's "Your Music" library
     - parameter track: the 'SpotifyTrack' object to save
     - parameter completionHandler: the callback to execute after response,
     brings the deletion success as parameter
     */
    public func delete(track: SpotifyTrack,
                       completionHandler: @escaping (Bool) -> Void) {
        guard let trackId = track.id else { return }
        delete(trackId: trackId, completionHandler: completionHandler)
    }
    /**
     Checks if a track is saved into user's "Your Music" library
     - parameter track: the id of the track to check
     - parameter completionHandler: the callback to execute after response,
     brings 'isSaved' as parameter
     */
    public func isSaved(trackId: String,
                        completionHandler: @escaping (Bool) -> Void) {
        tokenQuery { token in
            URLSession.shared.request(SpotifyQuery.contains,
                                      method: .GET,
                                      parameters: self.trackIdsParameters(for: trackId),
                                      headers: self.authorizationHeader(with: token)) { result in
                // Sends the 'isSaved' value back to the completion handler
                if  case let .success(data) = result,
                    let results = try? JSONDecoder().decode([Bool].self, from: data),
                    let saved = results.first {
                    completionHandler(saved)
                }
            }
        }
    }
    /**
     Checks if a track is saved into user's "Your Music" library
     - parameter track: the 'SpotifyTrack' object to check
     - parameter completionHandler: the callback to execute after response,
     brings 'isSaved' as parameter
     */
    public func isSaved(track: SpotifyTrack,
                        completionHandler: @escaping (Bool) -> Void) {
        guard let trackId = track.id else { return }
        isSaved(trackId: trackId, completionHandler: completionHandler)
    }
    // MARK: Helper functions
    /**
     Builds search query parameters for an element on Spotify
     - return: searchquery parameters
     */
    private func searchParameters(for type: SpotifyItemType,
                                  _ keyword: String) -> HTTPRequestParameters {
        return [SpotifyParameter.name: "\(keyword)*",
                SpotifyParameter.type: type.rawValue]
    }
    private func authorizationParameters(
                for application: SpotifyDeveloperApplication,
                with scopes: [SpotifyScope]) -> HTTPRequestParameters {
        return [SpotifyParameter.clientId: application.clientId,
                SpotifyParameter.responseType: SpotifyAuthorizationResponseType.code.rawValue,
                SpotifyParameter.redirectUri: application.redirectUri,
                SpotifyParameter.scope: SpotifyScope.string(with:
                    scopes)
        ]
    }
    /**
     Builds token parameters
     - return: parameters for token retrieval
     */
    private func tokenParameters(for application: SpotifyDeveloperApplication,
                                 from authorizationCode: String) -> HTTPRequestParameters {
        return [SpotifyParameter.clientId: application.clientId,
                SpotifyParameter.clientSecret: application.clientSecret,
                SpotifyParameter.grantType: SpotifyTokenGrantType.authorizationCode.rawValue,
                SpotifyParameter.code: authorizationCode,
                SpotifyParameter.redirectUri: application.redirectUri]
    }
    /**
     Builds token refresh parameters
     - return: parameters for token refresh
     */
    private func refreshTokenParameters(from oldToken: SpotifyToken) -> HTTPRequestParameters {
        return [SpotifyParameter.grantType: SpotifyTokenGrantType.refreshToken.rawValue,
                SpotifyParameter.refreshToken: oldToken.refreshToken]
    }
    /**
     Builds the authorization header for token refresh
     - return: authorization header
     */
    private func refreshTokenHeaders(for application: SpotifyDeveloperApplication) -> HTTPRequestHeaders {
        guard let auth = URLSession.authorizationHeader(user: application.clientId,
                                                        password: application.clientSecret) else { return [:] }
        return [auth.key: auth.value]
    }
    /**
     Builds the authorization header for user library interactions
     - return: authorization header
     */
    private func authorizationHeader(with token: SpotifyToken) -> HTTPRequestHeaders {
        return [SpotifyHeader.authorization: SpotifyAuthorizationType.bearer.rawValue +
            token.accessToken]
    }
    private func contentTypeHeader() -> HTTPRequestHeaders {
        return ["Content-Type": "application/json"]
    }
    /**
     Builds parameters for saving a track into user's library
     - return: parameters for track saving
     */
    private func trackIdsParameters(for trackId: String) -> HTTPRequestParameters {
        return [SpotifyParameter.ids: trackId]
    }
    private func playlistNameParameter(name: String) -> HTTPRequestParameters {
        return [SpotifyParameter.playlistName: name]
    }
    /**
     Generates a 'SpotifyToken' from a JSON response
     - return: the 'SpotifyToken' object
     */
    private func generateToken(from data: Data) -> SpotifyToken? {
        return try? JSONDecoder().decode(SpotifyToken.self, from: data)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(
                                            _ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues:
                        input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
