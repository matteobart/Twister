//
//  SongReplacerViewController.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class SongReplacerViewController: UIViewController {

    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var songTableView: UITableView!
    
    var artistName: String?
    var songName: String?
    
    var dict: [[String:Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        songTableView.dataSource = self
        songTableView.delegate = self
        // Do any additional setup after loading the view.songVC
    }
        
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension SongReplacerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongReplacerTableViewCell.identifier,
                                                       for: indexPath) as? SongReplacerTableViewCell else {
            return UITableViewCell()
        }
        //cell.creatorNameLabel.text = allPlaylists[1][indexPath.item].1
        cell.artistLabel.text = dict[indexPath.item]["artistName"] as? String
        cell.songLabel.text = dict[indexPath.item]["trackName"] as? String
        cell.songId = String(describing: dict[indexPath.item]["trackId"] as! Int)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
    
    
}
