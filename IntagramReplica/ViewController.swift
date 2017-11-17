//
//  ViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/7/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase
import FirebaseAuth
import FirebaseStorage
import SVProgressHUD
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import SwiftMessageBar

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    
    @IBOutlet weak var password_tf: UITextField!
    @IBOutlet weak var email_tf: UITextField!
    
    var FbLoginManager = FBSDKLoginManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference()
        
        
    }
    
    // MARK: - Action Buttons
    @IBAction func googleSignInAction(_ sender: UIButton) {
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func fbSignInAction(_ sender: UIButton) {
        FbLoginManager.logIn(withReadPermissions: ["public_profile","email"], from: self, handler: { (result, error) in
            if error == nil && result?.isCancelled == false{
                
                FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email,first_name,last_name,location,picture.width(720).height(720)"]).start(completionHandler: { (connection, result, error) in
                    
                    let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                    Auth.auth().signIn(with: credential ) { (user, error) in
                        if let err = error {
                            print(err)
                        } else {
                            if let res = result as? [String:Any] {
                                if let fname = res["first_name"] as? String,let lname = res["last_name"] as? String,let email = res["email"] as? String {
                                    
                                    
                                    if let uid = Auth.auth().currentUser?.uid {
                                        let userDict = ["FirstName": fname, "LastName":lname, "UserId": uid, "EmailID": email]
                                        databaseRef?.child("Users").child(uid).updateChildValues(userDict, withCompletionBlock: { (error, dataBaseRef) in
                                            if error == nil {
                                                if let picture = res["picture"] as? [String:Any]{
                                                    if let data = picture["data"] as? [String:Any], let url = data ["url"] as? String {
                                                        self.uploadingImage(url)
                                                    }
                                                }
                                            }
                                            else {
                                                print(error?.localizedDescription ?? "Error")
                                                SwiftMessageBar.showMessageWithTitle("Error", message: "Something went wrong.", type: .error)
                                            }
                                        })
                                        databaseRef?.child("PublicUsers").child(uid).updateChildValues(userDict, withCompletionBlock: { (error, dataBaseRef) in
                                            if error != nil {
                                                print(error?.localizedDescription ?? "Error")
                                                SwiftMessageBar.showMessageWithTitle("Error", message: "Something went wrong.", type: .error)
                                            }
                                        })
                                    }
                                }
                            }
                            SwiftMessageBar.showMessageWithTitle("Success", message: "Login Successful", type: .success)
                            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "HomeTabBarController") {
                                
                                self.present(controller, animated: true, completion: nil)
                            }
                        }
                    }
                })
            }
        })
    }
    
    @IBAction func signInAction(_ sender: UIButton) {
        guard let email = email_tf.text, let pass = password_tf.text else {
            return
        }
        
        if email.count == 0 || pass.count == 0 {
            SwiftMessageBar.showMessageWithTitle("Error", message: "Enter Username and Password", type: .error)
        } else {
            
            SVProgressHUD.show()
            Auth.auth().signIn(withEmail: email, password: pass) { (user, error) in
                if let err = error {
                    print(err.localizedDescription)
                    SwiftMessageBar.showMessageWithTitle("Error", message: "Username or Password wrong", type: .error)
                } else {
                    SwiftMessageBar.showMessageWithTitle("Success", message: "Sign In Successful", type: .success)
                    if let controller = self.storyboard?.instantiateViewController(withIdentifier: "HomeTabBarController") {
                        self.present(controller, animated: true, completion: nil)
                    }
                }
                //                self.email_tf.text = ""
                //                self.password_tf.text = ""
                SVProgressHUD.dismiss()
            }
        }
    }
    
    //MARK: Delegate Methods
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print(error.localizedDescription)
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        guard let profile = user.profile, let fname = profile.givenName, let lname = profile.familyName, let email = profile.email else {
            return
        }
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if let err = error {
                print(err.localizedDescription)
            } else {
                if let uid = Auth.auth().currentUser?.uid {
                    let userDict = ["FirstName": fname, "LastName":lname, "UserId": uid, "EmailID": email]
                    databaseRef?.child("Users").child(uid).updateChildValues(userDict)
                    databaseRef?.child("PublicUsers").child(uid).updateChildValues(userDict)
                    if profile.hasImage {
                        var url = profile.imageURL(withDimension: 500)
                        self.uploadingImage((url?.absoluteString)!)
                    }
                    if let controller = self.storyboard?.instantiateViewController(withIdentifier: "HomeTabBarController") {
                        SwiftMessageBar.showMessageWithTitle("Success", message: "Sign In Successful", type: .success)
                        self.present(controller, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Signing Out Google")
        try? Auth.auth().signOut()
    }
    
    //MARK: - Required Functions
    
    func uploadingImage(_ image_url: String) {
        guard let url = URL(string: image_url), let data = try? Data(contentsOf: url) else {
            return
        }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        if let id = Auth.auth().currentUser {
            let imagename = "UserImages/\(String(describing:id.uid)).jpeg"
            storageRef = StorageReference()
            storageRef = storageRef.child(imagename)
            storageRef.putData(data,metadata: metaData) { (storageMetaData, error) in
                let userImageUrl = storageMetaData?.downloadURL()?.absoluteString
                databaseRef?.child("Users").child(String(describing:id.uid)).updateChildValues(["userImageUrl": userImageUrl!])
                if error != nil {
                    SVProgressHUD.dismiss()
                    print(error?.localizedDescription ?? "Error")
                    SwiftMessageBar.showMessageWithTitle("Cannot upload", message: "Something went wrong.", type: .error)
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

