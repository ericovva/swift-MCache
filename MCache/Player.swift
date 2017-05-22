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
    
    /*ебушки воробушки, оказывается можно и так
    public func playyy(url: String) {
        let nsurl = NSURL(string: url)
        if let url = nsurl {
            print("Play AV from : \(url)")
            let item = AVPlayerItem(url: url as URL)
            self.AvPlayer = AVPlayer(playerItem: item)
            self.AVPlayerVC.player = self.AvPlayer
            self.AVPlayerVC.player?.play()
        } else {
            print ("Incorrect nsurl")
        }
    }
     */
    
    dynamic private func next() {
        var n = self.play_info.number! + 1;
        if (self.play_info.number == Global.PlayList.size() - 1) {
            n = 0;
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        _ = self.playAVSound(trackName: Global.PlayList.PlaylistItems[n].trackName!, path: NetLib.makePath(filename: Global.PlayList.PlaylistItems[n].filename!))
        print("Next song \(Global.PlayList.PlaylistItems[n].trackName!)")
    }
    
    dynamic private func previous() {
        var n = self.play_info.number! - 1;
        if (self.play_info.number == 0) {
            n = Global.PlayList.size() - 1;
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        _ = self.playAVSound(trackName: Global.PlayList.PlaylistItems[n].trackName!, path: NetLib.makePath(filename: Global.PlayList.PlaylistItems[n].filename!))
        print("Previous song \(Global.PlayList.PlaylistItems[n].trackName!)")
    }
    
    public func playAVSound(trackName : String, path: String) -> String {
        if (self.AVPlayerVC.player == nil) {
            print("Init remote control events...")
            UIApplication.shared.beginReceivingRemoteControlEvents()
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.nextTrackCommand.isEnabled = true
            commandCenter.nextTrackCommand.addTarget(self, action:#selector(self.next))
            commandCenter.previousTrackCommand.isEnabled = true
            commandCenter.previousTrackCommand.addTarget(self, action:#selector(self.previous))
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
            let item = AVPlayerItem(url: url as URL)

            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: item)
            self.AvPlayer = AVPlayer(playerItem: item)
            self.AVPlayerVC.player = self.AvPlayer
            self.AVPlayerVC.player?.play()
            self.updatePlayInfo(number: Global.PlayList.find_by_trackName(trackName: trackName), trackName: trackName, path: path, paused: false)
            return "playing"
        } else {
            print ("Incorrect nsurl")
        }
        return "error"
    }
    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        var n = self.play_info.number! + 1;
        if (self.play_info.number == Global.PlayList.size() - 1) {
            n = 0;
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        _ = self.playAVSound(trackName: Global.PlayList.PlaylistItems[n].trackName!, path: NetLib.makePath(filename: Global.PlayList.PlaylistItems[n].filename!))
        print("Next song \(Global.PlayList.PlaylistItems[n].trackName!)")
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
