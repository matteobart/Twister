//
//  PlaylistTableViewCell.swift
//  Adding-Content-to-Apple-Music
//
//  Created by Matteo Bart on 1/19/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var playlistNameLabel: UILabel!
    @IBOutlet weak var creatorNameLabel: UILabel!
    var playlistId: String = ""
    static let identifier = "PlaylistTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
