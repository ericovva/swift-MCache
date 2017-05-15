//
//  Menu.swift
//  MCache
//
//  Created by Эрик on 01.04.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.
//

import UIKit
import Alamofire
import CoreData
import AVFoundation
import AVKit

class Menu : UITableViewController {


    func check_files_in_cache() -> [NSManagedObject]{
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
        var songs: [NSManagedObject] = []
        do {
            songs = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return songs
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.load_from_yandex()
        refreshControl.endRefreshing()
    }
    
    func load_from_yandex() -> Void {
        _ = NetLib.get(root_path: "https://cloud-api.yandex.net/v1/disk/resources?path=/music") {
            (my_data, error) -> Void in
            if (error == nil) {
                if let error = my_data?["error"] {
                    print("Error \(error)")
                }
                if let _embedded = my_data?["_embedded"] {
                    if let items = _embedded["items"] {
                        if let files = items {
                            for file in files as! Array<Dictionary<String,Any>> {
                                
                                let path = file["path"] as! String;
                                let last_after_slash = NetLib.get_last_after_slash(s: path)
                                if (NetLib.cached[last_after_slash] == nil) {
                                    NetLib.cached[last_after_slash] = "";
                                    NetLib.content.append(last_after_slash)
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            } else {
                print("Error \(my_data!)")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
                
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
        self.refreshControl?.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        //From core data
        let songs = self.check_files_in_cache();
        for result in songs as [NSManagedObject] {
            let name = result.value(forKey: "name") as! String
            let path = result.value(forKey: "path") as! String
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(path)
            NetLib.cached[name] = fileURL.absoluteString
            NetLib.content.append(name)
        }
        self.tableView.reloadData()

        //From yandex
        self.load_from_yandex();

    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return NetLib.content.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell;
        cell.trackName.text = NetLib.content[indexPath.row]
        cell.path = NetLib.cached[NetLib.content[indexPath.row]]!;
        cell.number = indexPath.row;
        if (cell.path.characters.count > 0) {
            cell.downloadButton.isHidden = true
        } else {
            cell.downloadButton.isHidden = false
        }
        cell.loadingLine.isHidden = true
        if (cell.number == NetLib.play_info.number) {
            if (NetLib.player?.isPlaying == true) {
                cell.playPauseButtonOutlet.setImage(UIImage(named: "pause.png"), for: UIControlState.normal)
            }
            cell.trackName.textColor = UIColor(colorLiteralRed: 255, green: 0, blue: 0, alpha: 1)
        } else {
            cell.playPauseButtonOutlet.setImage(UIImage(named: "play.png"), for: UIControlState.normal)
            cell.trackName.textColor = UIColor(colorLiteralRed: 255, green: 255, blue: 255, alpha: 1)
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! SongCell
        NetLib.playAVSound(number: indexPath.row, name: cell.trackName.text!, path: cell.path, cell: cell)
        print("Play AV \(indexPath.row) \(cell.trackName.text!) \(cell.path)")
        //self.present(NetLib.AVPlayerVC, animated: true) {
          //  NetLib.AVPlayerVC.player?.play()
        //}
    }
}
