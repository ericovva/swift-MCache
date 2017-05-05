//
//  NetLib.swift
//  MCache
//
//  Created by Эрик on 02.04.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.
//

import Foundation
import AVFoundation

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
    class func playSound(path: String) {
        if self.player != nil {
            self.player?.stop()
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
                
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
            print ("Incorrect nsurl")
        }
        
    }
}
