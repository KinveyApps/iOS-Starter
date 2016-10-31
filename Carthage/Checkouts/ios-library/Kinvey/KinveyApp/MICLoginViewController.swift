//
//  ViewController.swift
//  KinveyApp
//
//  Created by Victor Barros on 2016-03-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import WebKit

open class MICLoginViewController: UIViewController {

    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var forceUIWebViewSwitch: UISwitch!
    @IBOutlet weak var useSafariViewControllerSwitch: UISwitch!
    
    open var completionHandler: User.UserHandler?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Kinvey.sharedClient.initialize(
            appKey: "kid_WyWKm0pPM-",
            appSecret: "081bc930604446de9153292f05c1b8e9"
        )
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func login(_ sender: UIButton) {
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        
        if useSafariViewControllerSwitch.isOn {
            User.presentMICViewController(redirectURI: redirectURI) { user, error in
                if let user = user {
                    self.userIdLabel.text = user.userId
                }
                self.completionHandler?(user, error)
            }
        } else {
            User.presentMICViewController(redirectURI: redirectURI, timeout: 60, micUserInterface: forceUIWebViewSwitch.isOn ? .uiWebView : .wkWebView) { (user, error) -> Void in
                if let user = user {
                    self.userIdLabel.text = user.userId
                }
                self.completionHandler?(user, error)
            }
        }
    }

}

