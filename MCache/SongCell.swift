//
//  SongCell.swift
//  MCache
//
//  Created by Эрик on 02.05.17.
//  Copyright © 2017 SwiftEnjoy. All rights reserved.
//

import UIKit
import AVFoundation
//import MediaPlayer

class SongCell: UITableViewCell {
    var path: String?
    var view: UITableViewController?
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var loadingLine: UIProgressView!
    @IBOutlet weak var playPauseButtonOutlet: UIButton!
    
    @IBAction func download(_ sender: Any) {
        NetLib.download_file(name: self.trackName.text!);
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
