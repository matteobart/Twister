/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Application's AppDelegate which configures the rest of the application's dependencies.
*/

import UIKit
import SpotifyKit

let spotifyManager = SpotifyManager(with:
    SpotifyManager.SpotifyDeveloperApplication(
        clientId:     spotifyClientId,
        clientSecret: spotifyClientSecret,
        redirectUri:  spotifyRedirectId
    )
)

/// The instance of `AuthorizationManager` which is responsible for managing authorization for the application.
var authorizationManager: AuthorizationManager = {
    return AuthorizationManager(appleMusicManager: appleMusicManager)
}()

/// The instance of `MediaLibraryManager` which manages the `MPPMediaPlaylist` this application creates.
var mediaLibraryManager: MediaLibraryManager = {
    return MediaLibraryManager(authorizationManager: authorizationManager)
}()

/// The instance of `AppleMusicManager` which handles making web service calls to Apple Music Web Services.
var appleMusicManager = AppleMusicManager()


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        spotifyManager.saveToken(from: url){ //once the token has been saved
            for childView in self.window?.rootViewController?.children ?? [] {
                if let mainVC = childView as? MainViewController {
                    mainVC.authController?.updateViews()
                    mainVC.authController?.checkIfDismiss()
                }
                if let authVC = childView as? AuthorizationViewController {
                    authVC.updateViews()
                }
                if let settingsVC = childView as? SettingsTableViewController {
                    settingsVC.unselectSelected()
                    settingsVC.updateLabels()
                }
            }
        }
        return true
    }
    
    // MARK: Application Life Cycle Methods
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

