//
//  FeedsViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/8/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import SVProgressHUD
class FeedsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var feedTableView: UITableView!
    var feedList: [Post] = []
    var likedPostDict: [String: String] = [:]
    var currentUserId = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedTableView.dataSource = self
        feedTableView.tableFooterView = UIView()
        feedTableView.rowHeight = 4*feedTableView.frame.height/5
        
        
        if let currentUserId = Auth.auth().currentUser?.uid{
            Messaging.messaging().subscribe(toTopic: currentUserId)
        }
        
        
        SVProgressHUD.show()
        getAllPosts()
    }
    
    func getAllPosts() {
        ManagePost.getAllPosts { (list) in
            if let postList = list as? [Post] {
                self.feedList = postList.sorted(by: { (a, b) -> Bool in
                    dateFormatter.dateFormat = dateFormat
                    guard let t1 = a.timestamp, let t2 = b.timestamp, let d1 = dateFormatter.date(from: t1), let d2 = dateFormatter.date(from: t2)  else {
                        return true
                    }
                    if d1 > d2 {
                        return true
                    } else {
                        return false
                    }
                })
            }
            DispatchQueue.main.async {
                self.feedTableView.reloadData()
                SVProgressHUD.dismiss()
            }
            
        }
        
        ManageUser.getMyLikeList { (dict) in
            if let Ldict = dict as? [String:String] {
                self.likedPostDict = Ldict
            }
            DispatchQueue.main.async {
                self.feedTableView.reloadData()
                SVProgressHUD.dismiss()
            }
        }
        
    }
    
    //MARK: - Action Outlets
    @IBAction func createFeedAction(_ sender: UIBarButtonItem) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "CreateFeedViewController") as? CreateFeedViewController {
            present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func signOutAction(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            do {
                let docUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let folderUrl = docUrl.appendingPathComponent("Connect")
                if FileManager.default.fileExists(atPath: folderUrl.path) {
                    try FileManager.default.removeItem(atPath: folderUrl.path)
                }
            } catch {
                print(error.localizedDescription)
            }
        } catch {
            print(error.localizedDescription)
        }
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as? FeedTableViewCell
        
        let post = feedList[indexPath.row]
        cell?.userNameLabel.text = post.userName
        cell?.postDescriptionLabel.text = post.desciption
        cell?.likeButton.tag = indexPath.row
        cell?.likeCountLabel.text = "\(String(describing: post.likes!)) likes"
        
        DispatchQueue.global().async {
            guard let url = URL(string: post.userImageUrl!), let image_data = try? Data(contentsOf: url) else {
                return
            }
            DispatchQueue.main.async {
                cell?.userImageView.image = UIImage(data: image_data)
            }
        }
        
        
        if likedPostDict[post.postId!] != nil {
            cell?.likeButton.isSelected = true
        } else {
            cell?.likeButton.isSelected = false
        }
        
        
        cell?.likeButton.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        
        guard let pid = post.postId, let url = post.postImageUrl else {
            return cell!
        }
        if let image = getImage(postId: pid) {
            DispatchQueue.main.async {
                cell?.postImageView.image = image
            }
        } else {
            DispatchQueue.global().async {
                if let pgId = post.postId, let image = self.saveImage(postId: pgId, image_url: url) {
                    DispatchQueue.main.async {
                        cell?.postImageView.image = image
                    }
                } else {
                    DispatchQueue.main.async {
                        cell?.postImageView.contentMode = .scaleAspectFill
                        cell?.postImageView.image = UIImage(named: "default")
                    }
                }
            }
        }
        return cell!
    }
    
    //MARK: - Required Functions
    @objc func toggleLike(sender: UIButton) {
        
        var post = feedList[sender.tag]
        databaseRef = Database.database().reference()
        
        if likedPostDict[post.postId!] == nil {
            sender.isSelected = true
            ManageUser.addFavorite(post: feedList[sender.tag])
            likedPostDict[post.postId!] = "1"
            databaseRef?.child("Posts/\(post.postId!)/likes").observeSingleEvent(of: .value, with: { (snap) in
                var val = snap.value as? Int
                val = val! + 1
                databaseRef?.child("Posts/\(post.postId!)/likes").setValue(val)
                DispatchQueue.main.async {
                    self.feedTableView.reloadData()
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        } else {
            sender.isSelected = false
            ManageUser.removeFavorite(post: feedList[sender.tag])
            likedPostDict.removeValue(forKey: post.postId!)
            databaseRef?.child("Posts/\(post.postId!)/likes").observeSingleEvent(of: .value, with: { (snap) in
                var val = snap.value as? Int
                val = val! - 1
                databaseRef?.child("Posts/\(post.postId!)/likes").setValue(val)
                DispatchQueue.main.async {
                    self.feedTableView.reloadData()
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
        //        if sender.isSelected {
        //            sender.isSelected = false
        //            ManageUser.removeFavorite(post: feedList[sender.tag])
        //        } else {
        //            sender.isSelected = true
        //            ManageUser.addFavorite(post: feedList[sender.tag])
        //        }
    }
    
    func getImage(postId: String) -> UIImage? {
        var image: UIImage?
        do {
            let docUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let folderUrl = docUrl.appendingPathComponent("Connect")
            let folderImageUrl = folderUrl.appendingPathComponent(postId+".jpeg")
            if let image_data = try? Data(contentsOf: folderImageUrl), let img =  UIImage(data: image_data){
                image = img
            }
        } catch {
            print(error.localizedDescription)
        }
        return image
    }
    
    func saveImage(postId: String, image_url: String) -> UIImage? {
        var image = UIImage(named: "default")
        do {
            let docUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            let folderUrl = docUrl.appendingPathComponent("Connect")
            let folderImageUrl = folderUrl.appendingPathComponent(postId+".jpeg")
            
            if !FileManager.default.fileExists(atPath: folderUrl.path) {
                try FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: false, attributes: nil)
            }
            
            guard let url = URL(string: image_url), let image_data = try? Data(contentsOf: url) else {
                return UIImage(named: "default")
            }
            
            try image_data.write(to: folderImageUrl)
            image = UIImage(data: image_data)
            return image!
        } catch {
            print(error)
        }
        return image
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
}
