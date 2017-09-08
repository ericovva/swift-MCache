//
//  SongCell.swift
//  MCache
//
//  Created by Эрик on 02.05.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation
import CoreData
//import MediaPlayer

class SongCell: UITableViewCell {
    var path: String?
    var view: UITableViewController?
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var loadingLine: UIProgressView!
    @IBOutlet weak var playPauseButtonOutlet: UIButton!
    
    @IBAction func download(_ sender: Any) {
        download_file();
    }
    
    @IBAction func play(_ sender: Any) {
        let st = Global.PLayer.playAVSound(trackName: self.trackName.text!)
        print("\(self.trackName.text!) state: \(st)")
        self.view?.tableView.reloadData()
        //self.player?.play()
        //playPauseButtonOutlet.setImage(UIImage(named: "pause.png"), for: UIControlState.normal)
        //self.view?.present(Global.PLayer.AVPlayerVC, animated: true) {
          //
        //}
        
    }
    
    func save_to_core_data(name: String, path: String) -> Bool{
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
    
    func download_file () {
        let name = self.trackName.text!
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
                    print("URL:: \(href)")
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
                        //print(response)
                        if let ur = response.destinationURL?.path {
                            let last_path_component = NetLib.get_last_after_slash(s: ur)
                            let saved = self.save_to_core_data(
                                name: name,
                                path: last_path_component
                            );
                            if (saved) {
                                Global.PlayList.updateDownloadedItem(trackName: name, filename: last_path_component)
                            }
                            Global.PlayList.PlaylistItems[n].downloading = false
                        }
                    }
                    .downloadProgress { progress in
                        Global.PlayList.PlaylistItems[n].download_progress = Float(progress.fractionCompleted)
                        if (true) {
                            Global.reload_tableview_in_main_queue()
                        }
                    }
                } else {
                    print("Error no href")
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Ошибка", message: "Не удалось сформировать ссылку", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Жаль", style: UIAlertActionStyle.default, handler: nil))
                        self.view?.present(alert, animated: true, completion: nil)
                    }

                    Global.PlayList.PlaylistItems[n].downloading = false
                    Global.reload_tableview_in_main_queue()
                }
            } else {
                print("Error")
                Global.PlayList.PlaylistItems[n].downloading = false
                Global.reload_tableview_in_main_queue()
            }
        }

    }

    public func changeState(state: String) {
        if (state == "play") {
            self.playPauseButtonOutlet.setImage(UIImage(named: "pause2.png"), for: UIControlState.normal)
            self.trackName.textColor = UIColor(colorLiteralRed: 255, green: 0, blue: 0, alpha: 1)
        } else {
            self.playPauseButtonOutlet.setImage(UIImage(named: "play.png"), for: UIControlState.normal)
            if (state == "stop") {
                self.trackName.textColor = UIColor(colorLiteralRed: 255, green: 255, blue: 255, alpha: 1)
            }
        }
    }
    
    public func changeDownload(fromData: Bool) {
        if (fromData) {
            self.downloadButton.isHidden = true
        } else {
            self.downloadButton.isHidden = false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
