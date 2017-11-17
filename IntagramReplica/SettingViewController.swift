//
//  SettingViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/10/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SwiftMessageBar
class SettingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var firstname_tf: UITextField!
    @IBOutlet weak var lastname_tf: UITextField!
    @IBOutlet weak var city_tf: UITextField!
    @IBOutlet weak var email_tf: UITextField!
    @IBOutlet weak var defaultImageView: UIImageView!
    
    var imagePickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerController.delegate = self
        SVProgressHUD.show()
        view_info()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        userImageView.layer.borderWidth = 1
        userImageView.layer.cornerRadius = userImageView.frame.height/2
        defaultImageView.layer.borderWidth = 1
        defaultImageView.layer.cornerRadius = defaultImageView.frame.height/2
    }
    
    func view_info() {
        let uid = Auth.auth().currentUser?.uid
        ManageUser.getUser (uid: uid!){(u) in
            if let user = u as? User {
                self.firstname_tf.text = user.firstname
                self.lastname_tf.text = user.lastname
                self.email_tf.text = user.email
                self.city_tf.text = user.city
                if let urlStr = user.userImageUrl, let url = URL(string: urlStr), let imgData = try? Data.init(contentsOf: url)  {
                    self.userImageView.image = UIImage(data: imgData)
                    self.userImageView.layer.cornerRadius = self.userImageView.frame.height/2
                }
            }
            SVProgressHUD.dismiss()
        }
    }
    
    @IBAction func updateInfoAction(_ sender: UIButton) {
        SVProgressHUD.show()
        databaseRef = Database.database().reference()
        uploadImage()
        let new_dict = ["FirstName": firstname_tf.text, "LastName": lastname_tf.text,"EmailID": email_tf.text, "City": city_tf.text]
        if let user = Auth.auth().currentUser, let udict = new_dict as? [String:String]  {
            databaseRef?.child("Users").child(user.uid).updateChildValues(udict, withCompletionBlock: { (error, dataBaseRef) in
            })
        }
        SVProgressHUD.dismiss()
        SwiftMessageBar.showMessageWithTitle("Success", message: "Profile update successful.", type: .success)
    }
    
    @IBAction func selectImageAction(_ sender: UIButton) {
        if imagePickerController.sourceType == .photoLibrary {
            imagePickerController.sourceType = .photoLibrary
        }
        if imagePickerController.sourceType == .camera {
            imagePickerController.sourceType = .camera
        }
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func changePassAction(_ sender: UIButton) {
    
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
            userImageView.image = img
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func uploadImage() {
        guard  let img = userImageView.image else {
            return
        }
        let data = UIImageJPEGRepresentation(img, 0.8)
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        databaseRef = Database.database().reference()
        let imagename = "UserImages/\(String(describing:Auth.auth().currentUser?.uid)).jpeg"
        storageRef = storageRef.child(imagename)
        
        storageRef.putData(data!,metadata: metaData) { (storageMetaData, error) in
            let userImageUrl = storageMetaData?.downloadURL()?.absoluteString
            if let id = Auth.auth().currentUser?.uid {
                databaseRef?.child("Users").child(String(describing:id)).updateChildValues(["userImageUrl": userImageUrl ?? ""])
            }
            if error != nil {
                SVProgressHUD.dismiss()
                print(error?.localizedDescription ?? "Error")
                SwiftMessageBar.showMessageWithTitle("Cannot upload", message: "Something went wrong.", type: .error)
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
