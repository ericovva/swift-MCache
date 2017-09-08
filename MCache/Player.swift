//
//  Player.swift
//  MCache
//
//  Created by Эрик on 17.05.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer

struct PlayInfo{
    var number : Int?
    var trackName : String?
    var path : String?
    var paused : Bool?
    //var cell : SongCell?
}

class Player : NSObject {
    var AVPlayerVC = AVPlayerViewController()
    var AvPlayer: AVPlayer?
    var play_info = PlayInfo(number: nil, trackName: nil, path: nil, paused: false)
    let commandCenter = MPRemoteCommandCenter.shared()
    
    @objc private func next() -> MPRemoteCommandHandlerStatus {
        var n = self.play_info.number! + 1;
        if (self.play_info.number == Global.PlayList.size() - 1) {
            n = 0;
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        _ = self.playAVSound(trackName: Global.PlayList.PlaylistItems[n].trackName!)
        print("Next song \(Global.PlayList.PlaylistItems[n].trackName!)")
        return .success
    }
    
    @objc private func previous() -> MPRemoteCommandHandlerStatus{
        var n = self.play_info.number! - 1;
        if (self.play_info.number == 0) {
            n = Global.PlayList.size() - 1;
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        _ = self.playAVSound(trackName: Global.PlayList.PlaylistItems[n].trackName!)
        print("Previous song \(Global.PlayList.PlaylistItems[n].trackName!)")
        return .success
    }
    
    @objc private func toggle() -> MPRemoteCommandHandlerStatus {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        print("Toggle ")
        return .success
    }
    
    @objc private func play() -> MPRemoteCommandHandlerStatus {
        self.AVPlayerVC.player?.play()
        self.play_info.paused = false
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        print("Play")
        return .success
    }
    
    @objc private func pause() -> MPRemoteCommandHandlerStatus {
        self.AVPlayerVC.player?.pause()
        self.play_info.paused = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        print("Pause")
        return .success
    }

    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        var n = self.play_info.number! + 1;
        if (self.play_info.number == Global.PlayList.size() - 1) {
            n = 0;
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        _ = self.playAVSound(trackName: Global.PlayList.PlaylistItems[n].trackName!)
        print("Next song \(Global.PlayList.PlaylistItems[n].trackName!)")
    }
    
    private func _findPath (trackName: String) -> String {
        let n = Global.PlayList.find_by_trackName(trackName: trackName)
        var path = ""
        if (n >= 0) {
            let p_item = Global.PlayList.PlaylistItems[n];
            if (!p_item.fromData!) {
                if (p_item.playing_url == nil) {
                    NetLib.makeTrackUrl(trackName: trackName, closure: self.playAVSound)
                } else {
                    path = p_item.playing_url!
                }
            } else {
                path = NetLib.makePath(filename: p_item.filename!)
            }
        } else {
            print("Error find_path: \(trackName) was not found in playlist")
        }
        return path
    }
    
    
    public func playAVSound(trackName : String) -> String {
        let path = _findPath(trackName: trackName);
        if (path == "") {
            return "getting url"
        }
        if (self.AVPlayerVC.player == nil) {
            print("Init remote control events...")
            UIApplication.shared.beginReceivingRemoteControlEvents()
            commandCenter.nextTrackCommand.isEnabled = true
            commandCenter.nextTrackCommand.addTarget(self, action:#selector(self.next))
            commandCenter.previousTrackCommand.isEnabled = true
            commandCenter.previousTrackCommand.addTarget(self, action:#selector(self.previous))
            commandCenter.pauseCommand.isEnabled = true
            commandCenter.pauseCommand.addTarget(self, action:#selector(self.pause))
            commandCenter.playCommand.isEnabled = true
            commandCenter.playCommand.addTarget(self, action:#selector(self.play))
        }
        
        if (self.AVPlayerVC.player != nil && self.play_info.trackName == trackName) {
            if (self.play_info.paused!) {
                self.AVPlayerVC.player?.play()
                self.updatePlayInfo(number: Global.PlayList.find_by_trackName(trackName: trackName), trackName: trackName, path: path, paused: false)
                return "continue"
            } else {
                self.AVPlayerVC.player?.pause()
                self.play_info.paused = true
                return "pause"
            }
        }
        let nsurl = NSURL(string: path)
        if let url = nsurl {
            print("Play AV from : \(url)")
            /*let npic = MPNowPlayingInfoCenter.default()
            npic.nowPlayingInfo = [
                MPMediaItemPropertyTitle: "Неизвестный",
                MPMediaItemPropertyArtist: "Неизвестный"
            ]*/
            let item = AVPlayerItem(url: url as URL)
            if (self.AVPlayerVC.player?.currentItem == nil) {
                self.AvPlayer = AVPlayer(playerItem: item)
                self.AVPlayerVC.player = self.AvPlayer
                self.AVPlayerVC.player?.automaticallyWaitsToMinimizeStalling = false
            } else {
                self.AvPlayer?.replaceCurrentItem(with: item)
            }
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: item)
            self.AVPlayerVC.player?.play()
            self.updatePlayInfo(number: Global.PlayList.find_by_trackName(trackName: trackName), trackName: trackName, path: path, paused: false)
            return "playing"
        } else {
            print ("Incorrect nsurl")
        }
        return "error"
    }
    
    private func updatePlayInfo(number : Int, trackName : String, path: String, paused: Bool) {
        self.play_info.number = number
        self.play_info.trackName = trackName
        self.play_info.path = path
        self.play_info.paused = paused
        //self.play_info.cell = cell
        //cell.trackName.textColor = UIColor(colorLiteralRed: 255, green: 0, blue: 0, alpha: 1)
    }
    

}
