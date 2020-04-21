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
    @IBOutlet weak var albumLabel: UILabel!
    var resultsVC: ResultsViewController?
    var songInformation: SongInformation?
    var index: Int? // index of the song from the previous frame
    var replacementSongs: [Song] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let originalSongData = songInformation else { return }
        songTableView.dataSource = self
        songTableView.delegate = self
        songLabel.text = originalSongData.name
        artistLabel.text = originalSongData.artist
        albumLabel.text = originalSongData.album
        // Do any additional setup after loading the view.songVC
    }
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true) {
            //self.resultsVC?.songsTableView.unselectSelected()
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.resultsVC?.songsTableView.unselectSelected()
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
        return replacementSongs.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongReplacerTableViewCell.identifier,
                                                       for: indexPath) as? SongReplacerTableViewCell else {
            return UITableViewCell()
        }
        cell.artistLabel.text = replacementSongs[indexPath.item].artist
        cell.songLabel.text = replacementSongs[indexPath.item].name
        cell.albumLabel.text = replacementSongs[indexPath.item].album
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let resultsVC = resultsVC else { return }
        guard let index = index else { return }
        dismiss(animated: true) {
            resultsVC.addToPlaylist(song: self.replacementSongs[indexPath.item], index: index)
        }
    }
}
