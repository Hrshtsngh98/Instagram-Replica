//
//  ChatMessage.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/13/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit

import Foundation
import JSQMessagesViewController

class ChatMessages {
    var message: JSQMessage
    var timeStamp: Int
    var userId: String
    init(msg: JSQMessage, tStamp: Int, tuser: String) {
        message = msg
        timeStamp = tStamp
        userId = tuser
    }
}
