//
//  ChangePassViewController.swift
//  IntagramReplica
//
//  Created by Harshit Singh on 11/11/17.
//  Copyright © 2017 Harshit Singh. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SVProgressHUD
import SwiftMessageBar


class ChangePassViewController: UIViewController {
    @IBOutlet weak var oldpass_tf: UITextField!
    @IBOutlet weak var newpass_tf: UITextField!
    @IBOutlet weak var confirmpass_tf: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference()
        // Do any additional setup after loading the view.
    }

    @IBAction func updateAction(_ sender: UIButton) {
        SVProgressHUD.show()
        
        if let user = Auth.auth().currentUser
        {
            if newpass_tf.text?.count == 0 || confirmpass_tf.text?.count == 0 {
                SwiftMessageBar.showMessageWithTitle("Error", message: "Password is empty.", type: .error)
                SVProgressHUD.dismiss()
            } else if newpass_tf.text == confirmpass_tf.text {
                let credentials = EmailAuthProvider.credential(withEmail: user.email!, password: oldpass_tf.text!)
                
                user.reauthenticate(with: credentials, completion: { (error) in
                    if error == nil {
                        user.updatePassword(to: self.newpass_tf.text!, completion: { (error) in
                            if error == nil {
                                SwiftMessageBar.showMessageWithTitle("Success", message: "Password Change Successful.", type: .success)
                                self.dismiss(animated: true, completion: nil)
                            } else {
                                SwiftMessageBar.showMessageWithTitle("Something went wrong", message: "Cannot change password.", type: .success)
                            }
                            SVProgressHUD.dismiss()
                        })
                    }
                    else {
                        SwiftMessageBar.showMessageWithTitle("Error", message: "Wrong old password.", type: .error)
                    }
                    SVProgressHUD.dismiss()
                })
            } else {
                SwiftMessageBar.showMessageWithTitle("Error", message: "Passwords do not match.", type: .error)
                SVProgressHUD.dismiss()
            }
        } else {
            SVProgressHUD.dismiss()
        }
    }
    
    @IBAction func cancel_press(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
