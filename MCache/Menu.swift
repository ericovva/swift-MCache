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
    
    @IBAction func right_item_action(_ sender: Any) {
        let items = Global.PlayList.PlaylistItems
        let time = Int(Date().timeIntervalSince1970)
        print("========== Begin \(time) ===========")
        for item in items {
            if (!item.downloading && !item.fromData!) {
                NetLib.download_file(name: item.trackName!)
            }
        }
    }

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
        self.load_from_yandex(refresh: refreshControl);
    }

    func load_from_yandex(refresh: UIRefreshControl?) -> Void {
        _ = NetLib.get(root_path: "https://cloud-api.yandex.net/v1/disk/resources?limit=10000&path=/music") {
            (my_data, error) -> Void in
            if (error == nil) {
                if let error = my_data?["error"] {
                    print("Error \(error)")
                    DispatchQueue.main.async {
                        let defaults = UserDefaults.standard
                        defaults.setValue(nil, forKey: "access_token")
                        self.performSegue(withIdentifier: "backToAuth", sender: nil)
                    }
                }
                if let _embedded = my_data?["_embedded"] {
                    if let items = _embedded["items"] {
                        if let files = items {
                            let tmpPlayList = Playlist(PlaylistItems: Global.PlayList.PlaylistItems.filter(){$0.fromData!})
                            var count = 0;
                            for file in files as! Array<Dictionary<String,Any>> {
                                let path = file["path"] as! String;
                                let last_after_slash = NetLib.get_last_after_slash(s: path)
                                tmpPlayList.addNewItem(trackName: last_after_slash, filename: "", state: "stop", fromData: false)
                                count+=1
                            }
                            print("Load from yandex succesfully. Count: \(count)")
                            DispatchQueue.main.async {
                                Global.PlayList = tmpPlayList
                                self.tableView.reloadData()
                                refresh?.endRefreshing()
                            }
                        }
                    }
                }
            } else {
                print("Error \(my_data!)")
            } 
        }
    }
    
    func loadList(){
        //load data here
        self.tableView.reloadData()
    }
    
    var cells  : [Int: SongCell] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
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
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        self.refreshControl?.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        //From core data
        let songs = self.check_files_in_cache();
        for result in songs as [NSManagedObject] {
            let name = result.value(forKey: "name") as! String
            let filename = result.value(forKey: "path") as! String
            Global.PlayList.addNewItem(trackName: name, filename: filename, state: "stop", fromData: true)
        }
        self.tableView.reloadData()
        
        //From yandex
        self.load_from_yandex(refresh: nil);

    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return Global.PlayList.size()
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell;
        Global.PlayList.setCell(cell: cell, row: indexPath.row)
        cell.view = self
        cell.downloadButton.isHidden = Global.PlayList.PlaylistItems[indexPath.row].downloading || Global.PlayList.PlaylistItems[indexPath.row].fromData!
        
        cell.loadingLine.isHidden = !Global.PlayList.PlaylistItems[indexPath.row].downloading
        if (Global.PlayList.PlaylistItems[indexPath.row].downloading) {
            cell.loadingLine.setProgress(Global.PlayList.PlaylistItems[indexPath.row].download_progress!, animated: true)
        }
        if (Global.PLayer.play_info.number != nil && indexPath.row == Global.PLayer.play_info.number) {
            if (Global.PLayer.play_info.paused!) {
                cell.playPauseButtonOutlet.setImage(UIImage(named: "play.png"), for: UIControlState.normal)
            } else {
                cell.playPauseButtonOutlet.setImage(UIImage(named: "pause2.png"), for: UIControlState.normal)
            }
        } else {
            cell.playPauseButtonOutlet.setImage(UIImage(named: "play.png"), for: UIControlState.normal)
        }
            return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //select
    }
}
