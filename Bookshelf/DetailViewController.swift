//
//  DetailViewController.swift
//  Bookshelf
//
//  Created by Victor Barros on 2016-02-08.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import SVProgressHUD
import MobileCoreServices
import AssetsLibrary
import Photos

class DetailViewController: UIViewController {

    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var takeChoosePictureButton: UIButton!

    var book: Book! {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let book = book {
            if let titleTextField = titleTextField {
                titleTextField.text = book.title
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.titleTextField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch identifier {
        case "save":
            if book == nil {
                book = Book()
            }
            book.title = titleTextField.text
            
            let store = DataStore<Book>.getInstance(.Sync)
            SVProgressHUD.show()
            store.save(book) { (book, error) -> Void in
                SVProgressHUD.dismiss()
                if let _ = book {
                    self.performSegueWithIdentifier(identifier, sender: sender)
                } else {
                    let alert = UIAlertController(title: "Error", message: "Operation not completed", preferredStyle: .Alert)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
            return false
        default:
            return true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

