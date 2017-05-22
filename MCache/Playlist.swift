//
//  Playlist.swift
//  MCache
//
//  Created by Эрик on 16.05.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.
//

import UIKit

struct PlaylistItem {
    var trackName: String?
    var state: String?
    var fromData: Bool?
    var filename: String?
    //var cell: SongCell?
}

class Playlist {
    var PlaylistItems : [PlaylistItem] = []
    //var Tracks = Set<String>()
    public func addNewItem(trackName: String, filename: String, state: String, fromData: Bool) {
        let found = self.find_by_trackName(trackName: trackName)
        if (found >= 0) { return }
        var item = PlaylistItem()
        item.filename = filename
        item.state = state
        item.fromData = fromData
        item.trackName = trackName
        self.PlaylistItems.append(item)
        //self.Tracks.insert(trackName)
    }
    
    public func updateItem(trackName: String, filename: String) {
        let n = self.find_by_trackName(trackName: trackName)
        if (n >= 0) {
            self.PlaylistItems[n].filename = filename
            self.PlaylistItems[n].fromData = true
        } else {
            print("Error: item with name \(trackName) not found")
        }

    }
    
    public func setCell(cell: SongCell, row: Int) {
        if (self.PlaylistItems.indices.contains(row)) {
            cell.makePath(filename: self.PlaylistItems[row].filename!)
            cell.changeState(state: self.PlaylistItems[row].state!)
            cell.changeDownload(fromData: self.PlaylistItems[row].fromData!)
            cell.trackName.text = self.PlaylistItems[row].trackName!
        } else {
            print("Indexes \(row) \(cell) error!")
        }
    }
    
    public func find_by_trackName(trackName: String) -> Int {
        var i = 0
        for item in self.PlaylistItems {
            if (trackName == item.trackName) {
                return i
            }
            i+=1
        }
        return -1
    }
    
    public func get(index: Int) -> PlaylistItem {
        return self.PlaylistItems[index]
    }
    
    public func size() -> Int {
        return self.PlaylistItems.count
    }
    
    
}
