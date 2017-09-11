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
    static var download_queue = Set<String>()
    static public func show_alert(title: String, mes: String, body: AnyObject) -> Void {
        /*                    DispatchQueue.main.async {
                                    let alert = UIAlertController(title: "Ошибка", message: "Не удалось сформировать ссылку", preferredStyle: UIAlertControllerStyle.alert)
                                    alert.addAction(UIAlertAction(title: "Жаль", style: UIAlertActionStyle.default, handler: nil))
                                    self.view?.present(alert, animated: true, completion: nil)
                                }*/
    }
    
    static public func reload_tableview_in_main_queue() {
        print ("Update")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        }
    }
    
    static var timer: Timer?
    
    static func start() {
        guard Global.timer == nil else { return }
        print("Start")
        Global.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reload_tableview_in_main_queue), userInfo: nil, repeats: true)
    }
    
    static func stop() {
        guard Global.timer != nil else { return }
        print("Stop")
        Global.timer?.invalidate()
        Global.timer = nil
    }
}
