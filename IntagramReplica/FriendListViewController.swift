//
//  FriendListViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/9/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import SVProgressHUD
import FirebaseAuth

class FriendListViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var friendTableView: UITableView!
    var userList: [User] = []
    var friendIdDict: [String:String] = [:]
    var friendList: [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Friends"
        friendTableView.dataSource = self
        friendTableView.tableFooterView = UIView()
        friendTableView.rowHeight = 100
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.global().async {
            self.getAllUser()
        }
    }
    
    func getAllUser() {
        SVProgressHUD.show()
        if let uid = Auth.auth().currentUser?.uid {
            ManageUser.getFriendListIds(uid: uid, completion: { (dict) in
                if let IdDict = dict as? [String:String] {
                    self.friendIdDict = IdDict
                }
            })
        }
        
        ManageUser.getAllUsers { (list) in
            if let users = list as? [User] {
                self.userList = users
            }
            for user in self.userList {
                if self.friendIdDict[user.userID!] != nil {
                    self.friendList.append(user)
                }
            }
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    self.friendTableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friend_cell", for: indexPath) as? UserTableViewCell
        let friend = friendList[indexPath.row]
        cell?.addFriendButton.tag = indexPath.row
        cell?.addFriendButton.addTarget(self, action: #selector(toggleFriend), for: .touchUpInside)
        cell?.userNameLabel.text = friend.firstname! + " " + friend.lastname!
        
        if friendIdDict[friend.userID!] != nil {
            cell?.addFriendButton.isSelected = true
        } else {
            cell?.addFriendButton.isSelected = false
        }
        
        DispatchQueue.global().async {
            guard let urlStr = friend.userImageUrl, let url = URL(string: urlStr), let imgData = try? Data(contentsOf: url) else {
                DispatchQueue.main.async {
                    cell?.userImageV?.image = UIImage(named: "user_default")
                }
                return
            }
            DispatchQueue.main.async {
                cell?.userImageV?.image = UIImage(data: imgData)
            }
        }
        return cell!
    }
    
    @objc func toggleFriend(sender: UIButton) {
        if sender.isSelected {
            let alertController = UIAlertController.init(title: "Confirm Remove", message: "Are you sure you want to remove?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                sender.isSelected = false
                ManageUser.removeFriend(user: self.friendList[sender.tag])
                self.friendList.remove(at: sender.tag)
                DispatchQueue.main.async {
                    self.friendTableView.reloadData()
                }
            })
            
            let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
            present(alertController, animated: true, completion: nil)
            
        } else {
            sender.isSelected = true
            ManageUser.addFriend(user: friendList[sender.tag])
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cont = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController {
            cont.friendObj = friendList[indexPath.row]
            cont.fromCont = "FriendList"
            navigationController?.pushViewController(cont, animated: true)
            //present(cont, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        friendIdDict.removeAll()
        userList.removeAll()
        friendList.removeAll()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
