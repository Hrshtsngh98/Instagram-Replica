//
//  CreateFeedViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/8/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import SVProgressHUD
import UITextView_Placeholder
import SwiftMessageBar
class CreateFeedViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var postTextView: UITextView!
    
    var imagePickerCont = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Post"
        imagePickerCont.delegate = self
        databaseRef = Database.database().reference()
        postImageView.layer.borderWidth = 1
        postTextView.placeholder = "Write your thoughts!"
        // Do any additional setup after loading the view.
    }

    @IBAction func uploadImageAction(_ sender: UIButton) {
        if imagePickerCont.sourceType == .photoLibrary {
            imagePickerCont.sourceType = .photoLibrary
        }
        present(imagePickerCont, animated: true, completion: nil)
    }
    
    @IBAction func postPostAction(_ sender: UIButton) {
        if postTextView.text.count == 0 {
            print("No text Entered")
        } else {
            guard let uid = Auth.auth().currentUser?.uid else {
                return
            }
            
            let postId = databaseRef?.child("Posts").childByAutoId().key
            dateFormatter.dateFormat = dateFormat
            let currentTime = dateFormatter.string(from: Date())
            let postDict = ["description": postTextView.text!, "likes": 0, "timeStamp": currentTime, "userId": uid, "postId": postId!] as [String : Any]
            databaseRef?.child("Posts").child(postId!).updateChildValues(postDict)
            uploadingImage(postId: postId!)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            postImageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    func uploadingImage(postId: String) {
        guard  let img = postImageView.image else {
            return
        }
        let data = UIImageJPEGRepresentation(img, 0.8)
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        let imagename = "PostImages/\(postId).jpeg"
        storageRef = StorageReference()
        storageRef = storageRef.child(imagename)
        storageRef.putData(data!,metadata: metaData) { (storageMetaData, error) in
            if let postImageUrl = storageMetaData?.downloadURL()?.absoluteString {
                databaseRef?.child("Posts").child(postId).updateChildValues(["postImageUrl": postImageUrl])
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
