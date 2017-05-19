//
//  DataSetImageTableViewCell.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 20/1/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit

class DataSetImageTableViewCell: UITableViewCell {

    @IBOutlet weak var dataSetImageView: UIImageView!
    @IBOutlet weak var correlationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
