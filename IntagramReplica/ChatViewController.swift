//
//  ChatViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/13/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import SVProgressHUD

class ChatViewController: JSQMessagesViewController {
    
    var friendObj: User?
    var currentUser = Auth.auth().currentUser?.uid
    var currentUserName: String = ""//Auth.auth().currentUser.
    var messages:Array<ChatMessages> = []
    var chatMessagesArray : Array<ChatMessages> = []
    var fromCont: String?
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        databaseRef = Database.database().reference()
        collectionView.backgroundView = UIImageView(image: UIImage(named: "app_background"))
        if fromCont == "FriendList" {
            tabBarController?.tabBar.isHidden = true
            title = (friendObj!.firstname)! + " " + (friendObj?.lastname)!
            senderId = currentUser
            senderDisplayName = currentUserName
            messages = getMessages()
            SVProgressHUD.dismiss()
        } else if fromCont == "AppDelegate"{
            ManageUser.getUser(uid: userId!,completion: { (user) in
                if let u = user as? User {
                    self.friendObj = u
                    self.title = (self.friendObj!.firstname)! + " " + (self.friendObj?.lastname)!
                    self.senderId = self.currentUser
                    self.senderDisplayName = self.currentUserName
                    self.messages = self.getMessages()
                    SVProgressHUD.dismiss()
                }
            })
        }
        SVProgressHUD.dismiss()
    }
    
    
    func getMessages() -> [ChatMessages] {
        messages = []
        chatMessagesArray = []
        var convoKey: String = ""
        if (friendObj?.userID)! < currentUser! {
            convoKey = (friendObj?.userID)! + "" + currentUser!
        }else {
            convoKey = currentUser! + (friendObj?.userID)!
        }
        databaseRef?.child("conversations/\(convoKey)").queryOrderedByKey().observe(.value, with: { (snapshot) in
            self.messages = []
            self.chatMessagesArray = []
            guard let value = snapshot.value as? NSDictionary else {return}
            for item in value {
                let msgDict = item.value as? Dictionary<String,String>
                let msg =  JSQMessage(senderId: msgDict?["senderId"], displayName: msgDict?["displayName"], text: msgDict?["message"])
                // database call
                let id = ""
                let chatMsg = ChatMessages(msg: msg!, tStamp: Int(item.key as! String)!, tuser: id)
                
                self.messages.append(chatMsg)
            }
            self.chatMessagesArray = self.messages.sorted(by: { (obj1, obj2) -> Bool in
                
                let ts1 = obj1.timeStamp
                let ts2 = obj2.timeStamp
                
                return(ts1 < ts2)
            })
            self.collectionView.reloadData()
            
        })
        self.collectionView.reloadData()
        return messages
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return chatMessagesArray.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        let message = chatMessagesArray[indexPath.row].message
        
        if currentUser == message.senderId {
            let outMessage = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(red: 12/255, green: 98/255, blue: 5/255, alpha: 1))
            return outMessage
        } else {
            let inMessage = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(red: 18/255, green: 13/255, blue: 98/255, alpha: 1))
            return inMessage
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        scrollToBottom(animated: true)
        let message = chatMessagesArray[indexPath.row].message
        let messageUsername = message.senderDisplayName
        return NSAttributedString(string: messageUsername!)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return chatMessagesArray[indexPath.row].message
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        
        //messages.append(message!)
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let convo = ["senderId": message?.senderId!, "displayName": message?.senderDisplayName!, "message": message?.text!]
        var conversationKey: String = ""
        
        if (friendObj?.userID)! < currentUser! {
            conversationKey = (friendObj?.userID)! + "" + currentUser!
        }else {
            conversationKey = currentUser! + (friendObj?.userID)!
        }
        
        let childUpdates = ["/conversations/\(conversationKey)/\(timestamp)": convo]
        databaseRef?.updateChildValues(childUpdates)
        let chMsg = ChatMessages(msg: message!, tStamp: timestamp, tuser: (friendObj?.userID)!)
        chatMessagesArray.append(chMsg)
        let notificationKey = databaseRef?.child("notificationRequests").childByAutoId().key
        let notification = ["message" : message?.text! , "username": friendObj?.userID, "senderId": senderId] as? [String: String]
        let notifyUpdates = ["/notificationRequests/\(notificationKey!)": notification!]
        databaseRef?.updateChildValues(notifyUpdates)
        finishSendingMessage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
        SVProgressHUD.dismiss()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
