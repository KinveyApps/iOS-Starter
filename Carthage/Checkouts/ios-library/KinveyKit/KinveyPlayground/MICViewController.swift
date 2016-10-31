//
//  MICViewController.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-16.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit

class MICViewController: UITableViewController {

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let block = { () -> Void in
            KCSClient.sharedClient().initializeKinveyServiceForAppKey(
                "kid_W1rPs9qy0",
                withAppSecret: "75f94ea7477c4bb7bd28c93b703bd10b",
                usingOptions: nil
            )
            
            KCSUser.setMICApiVersion("v2")
            
            KCSUser.presentMICLoginViewControllerWithRedirectURI(
                "kinveyAuthDemo://",
                timeout: 60 * 5,
                withCompletionBlock: { (user: KCSUser!, error: NSError!, actionResult: KCSUserActionResult) -> Void in
                    if (user != nil) {
                        let txt = "KCSUser: \(user.username) (\(user.userId))"
                        NSLog(txt)
                        UIAlertView(
                            title: "Success",
                            message: txt,
                            delegate: nil,
                            cancelButtonTitle: "OK"
                            ).show()
                    } else if (error != nil) {
                        let txt = "NSError: \(error)"
                        NSLog(txt)
                        UIAlertView(
                            title: "Error",
                            message: txt,
                            delegate: nil,
                            cancelButtonTitle: "OK"
                            ).show()
                    }
                    
                    NSLog("KCSUserActionResult: \(actionResult.rawValue)")
                    
                    if (indexPath.row == 2) {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            )
        }
        switch (indexPath.row) {
            case 1:
                block()
            case 2:
                let viewController = UIViewController()
                viewController.view = UIView()
                viewController.view.backgroundColor = UIColor.whiteColor()
                presentViewController(
                    viewController,
                    animated: true,
                    completion: block
                )
            default:
                assert(true, "do nothing!")
        }
    }

}
