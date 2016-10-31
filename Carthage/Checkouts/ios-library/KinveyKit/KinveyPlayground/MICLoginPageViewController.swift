//
//  MICLoginPageViewController.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-09.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit

class MICLoginPageViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    let redirectURI = "kinveyAuthDemo://"
    
    var user: KCSUser?
    var error: NSError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        KCSClient.sharedClient().initializeKinveyServiceForAppKey(
            "kid_WyYCSd34p",
            withAppSecret: "22a381bca79c407cb0efc6585aaed53e",
            usingOptions: nil
        )

        KCSUser.setMICApiVersion("v2")
        let url = KCSUser.URLforLoginWithMICRedirectURI(redirectURI)
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let url = request.URL!
        
        NSLog("\(url)")
        
        if KCSUser.isValidMICRedirectURI(redirectURI, forURL: url) {
            KCSUser.parseMICRedirectURI(
                redirectURI,
                forURL: url,
                withCompletionBlock: { (user: KCSUser!, error: NSError!, actionResult: KCSUserActionResult) -> Void in
                    self.user = user
                    self.error = error
                    
                    NSLog("\(user)")
                    NSLog("\(error)")
                }
            )
        }
        
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
