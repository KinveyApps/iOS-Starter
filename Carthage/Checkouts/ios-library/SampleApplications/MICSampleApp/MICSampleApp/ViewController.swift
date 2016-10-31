//
//  ViewController.swift
//  MICSampleApp
//
//  Created by Victor Barros on 2015-12-11.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class ViewController: UIViewController {
    
    var client: Client!

    @IBOutlet weak var textFieldAppKey: UITextField!
    @IBOutlet weak var textFieldAppSecret: UITextField!
    @IBOutlet weak var textFieldRedirectURI: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func touchUpInsidePresentMICViewControllerToLogin(sender: UIButton) {
        client = Client(appKey: textFieldAppKey.text!, appSecret: textFieldAppSecret.text!)
        User.presentMICViewController(
            redirectURI: NSURL(string: textFieldRedirectURI.text!)!,
            client: client
        ) { (user: User?, error: ErrorType?) in
            let alertVC = UIAlertController()
            if let user = user {
                alertVC.title = "Success"
                alertVC.message = user.userId
            } else if let error = error as? NSError {
                alertVC.title = "Error"
                alertVC.message = error.localizedDescription
            }
            alertVC.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alertVC, animated: true, completion: nil)
        }
    }

}

