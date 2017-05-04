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

class SongCell: UITableViewCell {
    var path = ""
    var player: AVAudioPlayer?
    
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var loadingLine: UIProgressView!
    
    @IBAction func download(_ sender: Any) {
        download_file(to_play: false);
    }
    
    @IBAction func play(_ sender: Any) {
        let name = self.trackName.text!
        print("Play \(name) \(path)")
        if (path.isEmpty) {
            print("Path not found for track \(name). Downloading file...")
            self.download_file(to_play: true)
        } else {
            playSound(path: path)
        }
        
    }

    func playSound(path: String) {
        let nsurl = NSURL(string: path)
        if let url = nsurl {
            print("Play from : \(url)")
            do {
                player = try AVAudioPlayer(contentsOf: url as URL)
                guard let player = player else { return }
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
    
    func download_file (to_play : Bool) {
        let name = self.trackName.text!
        self.loadingLine.isHidden = false;
        self.loadingLine.setProgress(0, animated: false)
        let escapedString = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        _ = NetLib.get(root_path: "https://cloud-api.yandex.net:443/v1/disk/resources/download?path=/music/" + escapedString) { (my_data, error) -> Void in
            if (error == nil) {
                if let href = my_data?["href"] {
                    let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        var escaped_name = escapedString
                        do {
                            let regex = try NSRegularExpression(pattern: "%")
                            let newString = regex.stringByReplacingMatches(in: escaped_name, options: [], range: NSMakeRange(0, escaped_name.characters.count), withTemplate: "")
                            escaped_name = newString
                            print(newString)

                        } catch {
                            print("ERROR IN REGEX")
                        }
                        let fileURL = documentsURL.appendingPathComponent(escaped_name)
                        return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                    }
                    
                    Alamofire.download(href as! String, to: destination).response { response in
                        //print(response)
                        if let ur = response.destinationURL?.path {
                            print(ur)
                            let saved = self.save_to_core_data(
                                name: name,
                                path: "file://\(ur)"
                            );
                            if (saved) {
                                self.path = "file://\(ur)"
                                self.downloadButton.isHidden = true
                                if (to_play) {
                                    print("Playing sound \(name)")
                                    self.playSound(path: self.path)
                                }
                            }
                        }
                        self.loadingLine.isHidden = true
                        
                        }
                        .downloadProgress { progress in
                            self.loadingLine.setProgress(Float(progress.fractionCompleted), animated: true)
                    }
                } else {
                    print("Error no href")
                }
            } else {
                print("Error")
            }
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
