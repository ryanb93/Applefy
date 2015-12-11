#This project no longer works.

#Applefy

An OSX application to store Spotify playlists as MP3's that can be imported into iTunes to be matched by Apple Music.

**Does not work if you have iTunes Match enabled**

**5 second silent songs mean song could not be found in iTunes, delete and add manually**

[<img src="http://i.imgur.com/Qy9A0VP.png" width="120px">  
Latest binary download](https://github.com/ryanb93/Applefy/releases)

Instructions
----

* Open the application and log in with your Spotify details.
* Select the playlist you want to transfer from the dropdown list.
* Press the 'Save Playlist' button.
* Navigate to your home folder and there will be a folder called Applefy.
* Inside this folder will be a folder with your playlist name containing MP3s.
* Open iTunes, go to the Playlists tab and make a new playlist.
* Drag the MP3 files into the playlist.
* Select all and right click. Choose 'Add to iCloud Music Library'
* Once the songs have been registered, right click again and 'Remove download', you can now stream or download the full song using your Apple Music subscription.

Development
----
To build the project you have to create a file called `Applefy/appkey.c`. The content must be set to the C-Code created under [Spotify Developer : My application keys](https://devaccount.spotify.com/my-account/keys/).

Limitations
----
Some of the music files will not be found by iTunes and so instead of matching the file it will just upload the 5 second silent clip. This is because the song name from Spotify does not match the iTunes name. Easiest way to fix this is just remove the song and add it manually, it doesn't happen very often.


Disclaimer
---

This application is in no way affiliated with, authorized, maintained, sponsored or endorsed by either Apple Inc. or Spotify. 

iTunes® is the registered trademark of Apple Inc.  
Spotify is the registered trademark of the Spotify Group
