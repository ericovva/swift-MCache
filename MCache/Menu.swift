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

class Menu : UITableViewController {
    var content : [String] = []
    var cached  : [String: String] = [:]
    func get_last_after_slash(s: String) -> String {
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
    func check_files_in_cache() -> [NSManagedObject]{
        //1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Song")
        
        //3
        var songs: [NSManagedObject] = []
        do {
            songs = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return songs
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = NetLib.get(root_path: "https://cloud-api.yandex.net/v1/disk/resources?path=/music") {
            (my_data, error) -> Void in
            if (error == nil) {
                if let error = my_data?["error"] {
                    print("Error \(error)")
                }
                if let _embedded = my_data?["_embedded"] {
                    if let items = _embedded["items"] {
                        if let files = items {
                            //From yandex
                            for file in files as! Array<Dictionary<String,Any>> {
                                let path = file["path"] as! String;
                                self.content.append(self.get_last_after_slash(s: path))
                                self.cached[self.get_last_after_slash(s: path)] = ""
                            }
                            //From core data
                            let songs = self.check_files_in_cache();
                            for result in songs as [NSManagedObject] {
                                let name = result.value(forKey: "name") as! String
                                let path = result.value(forKey: "path") as! String
                                self.cached[name] = path
                            }
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            } else {
                print("Error \(my_data)")
            }
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return content.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell;
        cell.trackName.text = self.content[indexPath.row]
        let path = self.cached[self.content[indexPath.row]]!;
        cell.path = path
        if (path.characters.count > 0) {
            cell.downloadButton.isHidden = true
        }
        cell.loadingLine.isHidden = true
        return cell
    }
    //override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    //    let cell = tableView.cellForRow(at: indexPath);
    //}
}
