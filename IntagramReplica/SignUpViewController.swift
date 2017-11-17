//
//  SignUpViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/7/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn
import SVProgressHUD
import SwiftMessageBar

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var firstname_tf: UITextField!
    @IBOutlet weak var lastname_tf: UITextField!
    @IBOutlet weak var email_tf: UITextField!
    @IBOutlet weak var city_tf: UITextField!
    @IBOutlet weak var password_tf: UITextField!
    @IBOutlet weak var confirmpass_tf: UITextField!
    @IBOutlet weak var user_imageV: UIImageView!
    
    var imagePickerController = UIImagePickerController()
    
    //MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerController.delegate = self
        databaseRef = Database.database().reference()
        storageRef = Storage.storage().reference()
        user_imageV.layer.borderWidth = 1
        user_imageV.layer.cornerRadius = user_imageV.frame.height/2

    }
    
    
    //MARK: - Button Actions
    @IBAction func signUpAction(_ sender: UIButton) {
        if firstname_tf.text?.count == 0 {
            popUpAlert(mess: "First Name")
        }
        else if lastname_tf.text?.count == 0 {
            popUpAlert(mess: "Last Name")
        }
        else if email_tf.text?.count == 0 {
            popUpAlert(mess: "Email")
        }
        else if city_tf.text?.count == 0 {
            popUpAlert(mess: "City")
        }
        else if password_tf.text?.count == 0 {
            popUpAlert(mess: "Password")
        }else  if confirmpass_tf.text?.count == 0 {
            popUpAlert(mess: "Confirm Password")
        } else if password_tf.text != confirmpass_tf.text {
            print("Password do not match!")
            SwiftMessageBar.showMessageWithTitle("Error", message: "Password do not match!", type: .error)
        }else {
            SVProgressHUD.show()
            Auth.auth().createUser(withEmail: email_tf.text!, password: password_tf.text!) { (user, error) in
                if error == nil {
                    var userDict = ["FirstName": self.firstname_tf.text, "LastName":self.lastname_tf.text, "UserId": user?.uid, "EmailID": self.email_tf.text, "City": self.city_tf.text]
                    if let id = user?.uid, let udict = userDict as? [String:String] {
                        databaseRef?.child("Users").child(id).updateChildValues(udict, withCompletionBlock: { (error, dataBaseRef) in
                            if error == nil {
                                self.uploadingImage()
                                SwiftMessageBar.showMessageWithTitle("Congrats!!", message: "Sign Up successful.", type: .success)
                                print("Sign Up successful.")
                            }
                            else {
                                print(error?.localizedDescription ?? "Error")
                                SwiftMessageBar.showMessageWithTitle("Error", message: "Something went wrong.", type: .error)
                                print("Something went wrong.")
                            }
                        })
                        userDict.removeValue(forKey: "EmailID")
                        databaseRef?.child("PublicUsers").child(id).updateChildValues(udict)
                    }
                    SVProgressHUD.dismiss()
                }else{
                    print(error?.localizedDescription ?? "Error")
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func uploadImageAction(_ sender: UIButton) {
        if imagePickerController.sourceType == .photoLibrary {
            imagePickerController.sourceType = .photoLibrary
        }
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func back_action(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Image Picker Functions
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
            user_imageV.image = img
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Inplemented Functions
    
    func uploadingImage() {
        guard  let img = user_imageV.image else {
            return
        }
        let data = UIImageJPEGRepresentation(img, 0.8)
        let metaData = StorageMetadata()
        
        metaData.contentType = "image/jpeg"
        
        if let id = Auth.auth().currentUser {
            let imagename = "UserImages/\(String(describing:id.uid)).jpeg"
            storageRef = StorageReference()
            storageRef = storageRef.child(imagename)
            storageRef.putData(data!,metadata: metaData) { (storageMetaData, error) in
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
    
    @IBAction func backAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func popUpAlert(mess: String) {
        let alert = UIAlertController(title: "Alert", message: mess, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
