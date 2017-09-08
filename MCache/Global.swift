//
//  Global.swift
//  MCache
//
//  Created by Эрик on 17.05.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.
//

import UIKit

class Global: NSObject {
    static var PlayList = Playlist()
    static var PLayer = Player()
    
    static public func show_alert(title: String, mes: String, body: AnyObject) -> Void {
            }
    
    static public func reload_tableview_in_main_queue() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        }
    }
}
