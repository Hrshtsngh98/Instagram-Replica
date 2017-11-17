//
//  Post.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/8/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

class Post {
    var desciption: String?
    var likes: Int?
    var timestamp: String?
    var userId: String?
    var postId: String?
    var postImageUrl: String?
    var userName: String?
    var userImageUrl: String?
    
    init(desc: String, likes: String, time: String, userId: String, postId: String, url: String ) {
        desciption = desc
        self.likes = Int(likes)
        self.userId = userId
        self.postId = postId
        timestamp = time
        userName = ""
        postImageUrl = url
        userImageUrl = ""
    }
    
    init(withDict dict: [String:Any]) {
        desciption = dict["description"] as? String
        likes = dict["likes"] as? Int
        userId = dict["userId"] as? String
        postId = dict["postId"] as? String
        postImageUrl = dict["postImageUrl"] as? String
        timestamp = dict["timeStamp"] as? String
        userName = ""
        userImageUrl = ""
    }
}

typealias handler = (Any) -> ()

class ManagePost: NSObject {
    static func getAllPosts(completion: @escaping handler) {
        databaseRef = Database.database().reference()
        
        databaseRef?.child("Posts").observe(.value, with: { (snapShot) in
            if let value = snapShot.value as? [String:Any] {
                var postList: [Post] = []
                for val in value {
                    if let dict = val.value as? [String:Any] {
                        let post = Post(withDict: dict)
                        databaseRef?.child("Users").child(post.userId!).observeSingleEvent(of: .value, with: { (userSnap) in
                            if let userVal = userSnap.value as? Dictionary<String,Any> {
                                if let fname = userVal["FirstName"] as? String, let lname = userVal["LastName"] as? String {
                                    post.userName = "\(fname) \(lname)"
                                }
                                
                                if let url = userVal["userImageUrl"] as? String {
                                    post.userImageUrl = url
                                }
                            }
                        })
                        postList.append(post)
                    }
                }
                completion(postList)
            }
        })
    }
}
