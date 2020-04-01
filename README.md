# Twister

## Description
Twister is an open-source solution to transfering playlists between Apple Music and Spotify. Twister is an iOS application and will soon be able to be found on the App Store.


## Setup

### Variables
To get this code to run you will need some API tokens from Apple and Spotify.
I would recommend setting these variables somewhere in the code for easiest set up:
``` swift
public var appleMusicDevKey = "nil"
public var spotifyClientId = "nil"
public var spotifyClientSecret = "nil"
public var spotifyRedirectId = "twister://callback"
```

### Apple Music
To create an Apple Music developer token, I highly suggest using [this link](https://gist.github.com/leemartin/0dac81a74a58f8587270dca9089ddb7f). I have found that other solutions do not produce accurate keys. 

### Spotify 
To get Spotify developer tokens follow [this link](https://developer.spotify.com/dashboard). You will need to use a Spotify account, but this is quick, easy, and free!


## License 
Currently, there is [no license](https://choosealicense.com/no-permission/) for this project. However feel free to fork and submit a pull request to make this project better. Please do not distribute this application without **explicit** permission. 
