//
//  NetLib.swift
//  MCache
//
//  Created by Эрик on 02.04.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.   
//
import UIKit
import Foundation
import CoreData
import Alamofire


class NetLib {
    
    class func get(root_path : String, completionHandler: @escaping (Dictionary<String, AnyObject>?, NSError?) -> Void) -> URLSessionTask{
        print("Get: \(root_path)");
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

    class func makePath(filename : String) -> String {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        return fileURL.absoluteString
    }
    
    class func makeTrackUrl(trackName: String, closure: @escaping ( String ) -> String) {
        let escapedString = trackName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        _ = NetLib.get(root_path: "https://cloud-api.yandex.net:443/v1/disk/resources/download?path=/music/\(escapedString)") { (my_data, error) -> Void in
            if (error == nil) {
                if let href = my_data?["href"] {
                    print("URL:: \(href)")
                    Global.PlayList.updatePlayingUrl(trackName: trackName, path: href as! String)
                    DispatchQueue.main.async {
                        _ = closure(trackName)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                    }
                }
            }
        }
    }
    
    class func save_to_core_data(name: String, path: String) -> Bool{
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else {
                return false
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Song", in: managedContext)!
        let song = NSManagedObject(entity: entity, insertInto: managedContext)
        song.setValue(name, forKeyPath: "name")
        song.setValue(path, forKeyPath: "path")
        do {
            try managedContext.save()
            print("Saved song \(name) with \(path)")
            return true
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return false
    }
    
    class func download_file (name: String) {
        Global.download_queue.insert(name)
        let n = Global.PlayList.find_by_trackName(trackName: name)
        if (n >= 0) {
            Global.PlayList.PlaylistItems[n].downloading = true
            Global.PlayList.PlaylistItems[n].download_progress = 0;
            Global.reload_tableview_in_main_queue()
        } else {
            print("Cant find playlistitem with name \(name)")
            return
        }
        
        let _escapedString = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        var escapedString = ""
        for c in _escapedString.characters {
            if c == "&" {
                escapedString.append("%26")
                continue
            }
            escapedString.append(c)
        }
        _ = NetLib.get(root_path: "https://cloud-api.yandex.net:443/v1/disk/resources/download?path=/music/\(escapedString)") { (my_data, error) -> Void in
            if (error == nil) {
                if let href = my_data?["href"] {
                    print("Downloading url:  \(href)")
                    let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        var escaped_name = escapedString
                        do {
                            let regex = try NSRegularExpression(pattern: "%")
                            let newString = regex.stringByReplacingMatches(in: escaped_name, options: [], range: NSMakeRange(0, escaped_name.characters.count), withTemplate: "")
                            escaped_name = newString
                        } catch {
                            print("ERROR IN REGEX")
                        }
                        let fileURL = documentsURL.appendingPathComponent(escaped_name)
                        return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                    }
                    
                    Alamofire.download(href as! String, to: destination).response { response in
                        if let ur = response.destinationURL?.path {
                            let last_path_component = NetLib.get_last_after_slash(s: ur)
                            let saved = NetLib.save_to_core_data(
                                name: name,
                                path: last_path_component
                            );
                            if (saved) {
                                Global.PlayList.updateDownloadedItem(trackName: name, filename: last_path_component)
                            }
                            Global.PlayList.PlaylistItems[n].downloading = false
                            Global.download_queue.remove(name)
                            if Global.download_queue.isEmpty {
                                let time = Int(Date().timeIntervalSince1970)
                                print("============ Done \(time) ==========")
                            }
                            Global.stop()
                        }
                        }
                        .downloadProgress { progress in
                            Global.PlayList.PlaylistItems[n].download_progress = Float(progress.fractionCompleted)
                            if (true) {
                                Global.start()
                            }
                    }
                } else {
                    print("Error no href")
                    Global.download_queue.remove(name)
                    Global.PlayList.PlaylistItems[n].downloading = false
                    Global.reload_tableview_in_main_queue()
                }
            } else {
                print("Error")
                Global.download_queue.remove(name)
                Global.PlayList.PlaylistItems[n].downloading = false
                Global.reload_tableview_in_main_queue()
            }
        }
        
    }

    
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
