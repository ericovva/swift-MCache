//
//  NetLib.swift
//  MCache
//
//  Created by Эрик on 02.04.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.   
//
import UIKit
import Foundation
import AVFoundation
import AVKit
struct PlayInfo{
    var active = false
    var number : Int?
    var name : String?
    var path : String?
    var cell : SongCell?
}

class NetLib {
    class func get(root_path : String, completionHandler: @escaping (Dictionary<String, AnyObject>?, NSError?) -> Void) -> URLSessionTask{
        print(root_path);
        let my_url = NSURL(string: root_path);
        let request = NSMutableURLRequest(url: my_url! as URL)
        request.httpMethod = "GET"
        let defaults = UserDefaults.standard
        let token = defaults.string(forKey: "access_token")
        request.addValue("OAuth \(token!)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            // Check for error
            if error != nil
            {
                print("error=\(error!)")
                return
            }
            do {
                if let json_data = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, AnyObject> {
                    completionHandler(json_data, nil)
                    
                    return
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
        }
        task.resume()
        return task
    }
    
    class func get_last_after_slash(s: String) -> String {
        var r = "";
        for c in s.characters.reversed() {
            if (c == "/")  {
                break
            }
            else {
                r = "\(c)\(r)"
            }
        }
        return r
    }
    static var player: AVAudioPlayer?
    static var content : [String] = []
    static var cached  : [String: String] = [:]
    static var play_info = PlayInfo()
    static var AVPlayerVC = AVPlayerViewController()
    static var AvPlayer: AVPlayer?

    class func updatePlayInfo(active : Bool, number : Int, name : String, path: String, cell: SongCell) {
        self.play_info.active = active
        self.play_info.number = number
        self.play_info.name = name
        self.play_info.path = path
        self.play_info.cell = cell
        cell.trackName.textColor = UIColor(colorLiteralRed: 255, green: 0, blue: 0, alpha: 1)
    }
    
    class func playAVSound(number : Int, name : String, path: String, cell: SongCell) {
        let nsurl = NSURL(string: path)
        if let url = nsurl {
            print("Play AV from : \(url)")
            self.AvPlayer = AVPlayer(url: url as URL)
            self.AVPlayerVC.player = self.AvPlayer
            self.AVPlayerVC.player?.play()
        } else {
            print ("Incorrect nsurl")
        }

    }
    
    class func playSound(number : Int, name : String, path: String, cell: SongCell) {
        if (self.player != nil) {
            if (self.player?.isPlaying == true){
                self.player?.stop()
                self.play_info.active = false
                self.play_info.cell?.playPauseButtonOutlet.setImage(UIImage(named: "play.png"), for: UIControlState.normal)
                print("1Info \(self.play_info.number) cell \(cell.number)")
                if (self.play_info.number! == cell.number!) {
                    return
                }
            } else {
                print("2Info \(self.play_info.number) cell \(cell.number)")
                if (self.play_info.number! == cell.number!) {
                            print("3Info \(self.play_info.number) cell \(cell.number)")
                    self.player?.play()
                    self.play_info.active = true
                    self.play_info.cell?.playPauseButtonOutlet.setImage(UIImage(named: "pause.png"), for: UIControlState.normal)
                    return
                }
            }
            self.play_info.cell?.trackName.textColor = UIColor(colorLiteralRed: 255, green: 255, blue: 255, alpha:1)
        }
        let nsurl = NSURL(string: path)
        if let url = nsurl {
            print("Play from : \(url)")
            //let mpic = MPNowPlayingInfoCenter.default()
            //mpic.nowPlayingInfo = [MPMediaItemPropertyTitle: path, MPMediaItemPropertyArtist:"path"]
            do {
                NetLib.player = try AVAudioPlayer(contentsOf: url as URL)
                guard let player = self.player else { return }
                player.prepareToPlay()
                player.volume = 1.0
                NetLib.updatePlayInfo(active: true, number: number, name: name, path: path, cell: cell)
                cell.playPauseButtonOutlet.setImage(UIImage(named: "pause.png"), for: UIControlState.normal)
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
            print ("Incorrect nsurl")
        }
    }
    
    class func pauseSound() {
        if (self.player?.isPlaying == true) {
            self.player?.stop()
            //playPauseButtonOutlet.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
        } else {
            self.player?.play()
            //playPauseButtonOutlet.setImage(UIImage(named: "pause.png"), forState: UIControlState.Normal)
        }
        return
    }
    
    /* without alamofire
     class func downlaod_file(url: URL, to localUrl: URL, completion: @escaping () -> ()) {
     let sessionConfig = URLSessionConfiguration.default
     let session = URLSession(configuration: sessionConfig)
     let request = URLRequest(url: url)
     let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
     if let tempLocalUrl = tempLocalUrl, error == nil {
     // Success
     if let statusCode = (response as? HTTPURLResponse)?.statusCode {
     print("Success: \(statusCode)")
     }
     
     do {
     try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
     completion()
     } catch (let writeError) {
     print("error writing file \(localUrl) : \(writeError)")
     }
     
     } else {
     print("Failure: %@", error?.localizedDescription ?? 1);
     }
     }
     task.resume()
     }
     */
}
