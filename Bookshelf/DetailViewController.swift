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
    
    var authorsTVC: AuthorsTableViewController!

    var store: DataStore<Book>!
    
    var book: Book! {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let book = book, let titleTextField = titleTextField {
            titleTextField.text = book.title
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.titleTextField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    @IBAction func addAuthor(_ sender: Any) {
        authorsTVC.tableView.beginUpdates()
        authorsTVC.authors.append(Author())
        let indexPath = IndexPath(row: authorsTVC.authors.count - 1, section: 0)
        authorsTVC.tableView.insertRows(at: [indexPath], with: .automatic)
        authorsTVC.tableView.endUpdates()
        let cell = authorsTVC.tableView.cellForRow(at: indexPath) as? AuthorTableViewCell
        if let cell = cell {
            cell.textField.becomeFirstResponder()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "authors":
                authorsTVC = segue.destination as? AuthorsTableViewController
                authorsTVC.authors = book.authors.map { $0 }
            default:
                break
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "save":
            if book == nil {
                book = Book()
            }
            book.title = titleTextField.text
            book.authors.removeAll()
            book.authors.append(objectsIn: authorsTVC.authors)
            SVProgressHUD.show()
            
            store.save(book, options: nil) {
                SVProgressHUD.dismiss()
                switch $0 {
                case .success:
                    self.performSegue(withIdentifier: identifier, sender: sender)
                case .failure:
                    let alert = UIAlertController(title: "Error", message: "Operation not completed", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            return false
            
        case "cancel":
            if book == nil {
                book = Book()
            }
            
            SVProgressHUD.show()
            if let bookId = book.entityId {
                SVProgressHUD.dismiss()

                //user cancelled, reload book from the cache to disacard any local changes
                store.find(bookId, options: nil) {
                    switch $0 {
                    case .success(let cachedBook):
                        self.book = cachedBook
                    case .failure:
                        break
                    }
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

