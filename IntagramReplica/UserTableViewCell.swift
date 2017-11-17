//
//  UserTableViewCell.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/9/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageV: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var addFriendButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageV.layer.borderWidth = 1
        userImageV.layer.cornerRadius = userImageV.frame.height/2
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
