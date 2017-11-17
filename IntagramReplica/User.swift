//
//  User.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/8/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

class User {
    
    var firstname: String?
    var lastname: String?
    var city: String?
    var email: String?
    var userImageUrl: String?
    var userID: String?
    
    init(withsnap snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? Dictionary<String,Any> else { return }
        userID = dict["UserId"] as? String
        firstname = dict["FirstName"] as? String
        lastname = dict["LastName"] as? String
        city = dict["City"] as? String
        email = dict["EmailID"] as? String
        userImageUrl = dict["userImageUrl"] as? String
    }
    
    init(withDict dict_user: [String:Any]) {
        guard let dict = dict_user as? Dictionary<String,Any> else { return }
        userID = dict["UserId"] as? String
        firstname = dict["FirstName"] as? String
        lastname = dict["LastName"] as? String
        city = dict["City"] as? String
        email = dict["EmailID"] as? String
        userImageUrl = dict["userImageUrl"] as? String
    }
}

class ManageUser: NSObject {
    
    static func getUser(uid: String,completion: @escaping handler){
        var user: User?
        databaseRef = Database.database().reference()
        databaseRef?.child("Users").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            user = User(withsnap: snapshot)
            completion(user)
        }
    }
    
    static func getAllUsers(completion: @escaping handler) {
        databaseRef = Database.database().reference()
        databaseRef?.child("Users").observe(.value, with: { (snapshot) in
            if let userDicts = snapshot.value as? [String:[String:String]]{
                var userArray:[User] = []
                for (key,value) in userDicts {
                    //if let val = value as?
                    userArray.append(User(withDict: value))
                }
                completion(userArray)
            }
        })
    }
    
    static func addFav(post: Post, completion: @escaping handler) {
        databaseRef = Database.database().reference()
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        databaseRef?.child("PublicUsers").child(uid).child("LikedPosts").updateChildValues([post.postId!:"1"], withCompletionBlock: { (error, ref) in
            if error != nil {
                completion(false)
            } else {
                completion(true)
            }
        })
    }
    
    static func addFavorite(post: Post) {
        databaseRef = Database.database().reference()
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        databaseRef?.child("PublicUsers").child(uid).child("LikedPosts").updateChildValues([post.postId!:"1"])
        //changeLikeCount(post: post, val: 1)
    }
    
    static func removeFavorite(post: Post) {
        databaseRef = Database.database().reference()
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        databaseRef?.child("PublicUsers").child(uid).child("LikedPosts").child(post.postId!).removeValue()
        //changeLikeCount(post: post, val: -1)
    }
    
    static func changeLikeCount(post: Post, val: Int) {
        databaseRef = Database.database().reference()
        databaseRef?.child("Posts").child(post.postId!).observeSingleEvent(of: .value, with: { (snapShot) in
            if let value = snapShot.value as? [String:Any] {
                let newVal = value["likes"] as! Int + val
                let newDict = ["likes": newVal]
                databaseRef?.child("Posts").child(post.postId!).updateChildValues(newDict)
            }
        })
    }
    
    static func getMyLikeList(completion: @escaping handler) {
        databaseRef = Database.database().reference()
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        databaseRef?.child("PublicUsers").child(uid).child("LikedPosts").observe(.value, with: { (snapshot) in
            if let dict = snapshot.value as? [String:String] {
                completion(dict)
            }
        })
    }
    
    static func addFriend(user: User) {
        if let uid = Auth.auth().currentUser?.uid {
            databaseRef = Database.database().reference()
            databaseRef?.child("PublicUsers").child(uid).child("FriendList").updateChildValues([user.userID!:"id"])
        }
    }
    
    static func removeFriend(user: User) {
        if let uid = Auth.auth().currentUser?.uid {
            databaseRef = Database.database().reference()
            databaseRef?.child("PublicUsers").child(uid).child("FriendList").child(user.userID!).removeValue()
        }
    }
    
    static func getFriendListIds(uid: String, completion: @escaping handler) {
        databaseRef = Database.database().reference()
        databaseRef?.child("PublicUsers").child(uid).child("FriendList").observe(.value, with: { (snapshot) in
            if let val = snapshot.value as? Dictionary<String,String> {
                completion(val)
            }
        })
    }
}
