//
//  AllUserViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/9/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import SVProgressHUD
import FirebaseAuth

class AllUserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var allUserTableView: UITableView!
    var userList: [User] = []
    var friendIdDict: [String:String] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        allUserTableView.dataSource = self
        allUserTableView.tableFooterView = UIView()
        allUserTableView.rowHeight = 100
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
                DispatchQueue.main.async {
                    self.allUserTableView.reloadData()
                }
            }
            SVProgressHUD.dismiss()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "user_cell", for: indexPath) as? UserTableViewCell
        let user = userList[indexPath.row]
        cell?.addFriendButton.tag = indexPath.row
        cell?.addFriendButton.addTarget(self, action: #selector(toggleFriend), for: .touchUpInside)
        cell?.userNameLabel.text = user.firstname! + " " + user.lastname!
        
    
        if friendIdDict[user.userID!] != nil {
            cell?.addFriendButton.isSelected = true
        } else {
            cell?.addFriendButton.isSelected = false
        }
        
        DispatchQueue.global().async {
            guard let urlStr = user.userImageUrl, let url = URL(string: urlStr), let imgData = try? Data(contentsOf: url) else {
                DispatchQueue.main.async {
                    cell?.userImageV?.image = UIImage(named: "user_default")
                }
                return
            }
            DispatchQueue.main.async {
                cell?.userImageV?.image = UIImage(data: imgData)
            }
        }
    
        if let uid = Auth.auth().currentUser?.uid {
            if uid == user.userID {
                cell?.addFriendButton.isEnabled = false
                cell?.addFriendButton.setImage(nil, for: .normal)
                cell?.userNameLabel.text = "You"
            }
        }
        return cell!
    }
    
    @objc func toggleFriend(sender: UIButton) {
        if sender.isSelected {
            sender.isSelected = false
            ManageUser.removeFriend(user: userList[sender.tag])
        } else {
            sender.isSelected = true
            ManageUser.addFriend(user: userList[sender.tag])
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        friendIdDict.removeAll()
        userList.removeAll()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
