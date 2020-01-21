//
//  SongReplacerTableViewCell.swift
//  
//
//  Created by Matteo Bart on 1/20/20.
//

import UIKit

class SongReplacerTableViewCell: UITableViewCell {
    static let identifier = "SongCell"
    
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!

    var songId: String? 
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
