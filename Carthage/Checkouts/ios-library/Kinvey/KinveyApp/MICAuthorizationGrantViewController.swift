//
//  MICAuthorizationGrantViewController.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class MICAuthorizationGrantViewController: UIViewController {
    
    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var labelUserID: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Kinvey.sharedClient.initialize(
            appKey: "kid_rJVLE1Z5",
            appSecret: "cd385840cbd94e2caaa8f824c2ff7f46"
        )
    }
    
    @IBAction func login(_ sender: UIButton) {
        let redirectURI = URL(string: "micAuthGrantFlow://")!
        User.loginWithAuthorization(
            redirectURI: redirectURI,
            username: textFieldUsername.text!,
            password: textFieldPassword.text!
        ) { user, error in
            if let user = user {
                self.labelUserID.text = user.userId
            } else if let error = error {
                self.labelUserID.text = "Error: \((error as NSError).localizedDescription)"
            } else {
                self.labelUserID.text = ""
            }
        }
    }
    
}
