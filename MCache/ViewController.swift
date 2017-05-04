//
//  ViewController.swift
//  MCache
//
//  Created by Эрик on 16.03.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webV: UIWebView!
    func _get_access_token(time : Int) {
        webV.delegate = self;
        
        let url = "https://oauth.yandex.ru/authorize?response_type=token&client_id=ee932422303d4a89b5588f2e7301a83b";
        webV.loadRequest(URLRequest(url: URL(string: url)!))
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        let defaults = UserDefaults.standard
        let time = Int(Date().timeIntervalSince1970);
        var authorized = false
        if let token = defaults.string(forKey: "access_token") {
            if let login_time = defaults.object(forKey: "login_time") {
                if let expires_in = defaults.object(forKey: "expires_in") {
                    if (time < (login_time as! Int) + (expires_in as! Int)) {
                        authorized = true
                        print(token)
                        performSegue(withIdentifier: "menu", sender: nil)
                    }
                }
            }
        }
        if (authorized == false){
            self._get_access_token(time: time);
        }

    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    public func webViewDidFinishLoad(_ webView: UIWebView) {
        let currentURL : String = (webV.request?.url!.absoluteString)!
        var dict = [String:String]()
        let components = URLComponents(url: URL(string: String(currentURL.characters.map {
                $0 == "#" ? "?" : $0
            }
        ))!, resolvingAgainstBaseURL: false)!
        if let queryItems = components.queryItems {
            for item in queryItems {
                dict[item.name] = item.value!
            }
        }
        if ((dict["access_token"] != nil) && dict["expires_in"] != nil) {
            let defaults = UserDefaults.standard
            let time = Int(Date().timeIntervalSince1970)
            defaults.setValue(time, forKey: "login_time")
            defaults.setValue(Int(dict["expires_in"]!), forKey: "expires_in")
            defaults.setValue(dict["access_token"], forKey: "access_token")
            defaults.synchronize()
            print ("Save token")
            performSegue(withIdentifier: "menu", sender: nil)
        } else if (dict["error"] != nil) {
            print ("AUTH ERROR")
            print (dict["error"]!)
        }
    }
    public func webViewDidStartLoad(_ webView: UIWebView) {
        let currentURL : String = (webV.request?.url!.absoluteString)!
        print (currentURL);
    }
    

}

