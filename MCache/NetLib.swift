//
//  NetLib.swift
//  MCache
//
//  Created by Эрик on 02.04.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.   
//
import UIKit
import Foundation



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
