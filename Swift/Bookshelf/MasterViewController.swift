//
//  MasterViewController.swift
//  Bookshelf
//
//  Created by Victor Barros on 2016-02-08.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import SVProgressHUD

class MasterViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!

    var detailViewController: DetailViewController? = nil
    var books = [Book]()
    var selectedBook: Book?
    
    lazy var store: DataStore<Book>! = {
        //Create a DataStore of type "Sync"
        return DataStore<Book>.getInstance(.Sync)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MasterViewController.insertNewBook(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        reloadData()
    }
    
    func reloadData(searchText: String = "") {
        SVProgressHUD.show()
        var query: Query
        if (searchText != "") {
            query = Query(format: "title CONTAINS[c] %@", searchText)
        } else {
            query = Query()
        }
        store.find(query) { (books, error) -> Void in
            SVProgressHUD.dismiss()
            if let books = books {
                self.books = books
                if self.refreshControl?.refreshing ?? false {
                    self.refreshControl?.endRefreshing()
                }
                self.tableView.reloadData()
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewBook(sender: AnyObject) {
        selectedBook = Book()
        performSegueWithIdentifier("showDetail", sender: sender)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let index = self.tableView.indexPathForSelectedRow {
                selectedBook = books[index.row];
            }
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            controller.store = self.store
            controller.book = selectedBook
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let book = books[indexPath.row]
        cell.textLabel!.text = book.title
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let book = books[indexPath.row]
            do {
                SVProgressHUD.show()
                try store.remove(book) { (count, error) -> Void in
                    SVProgressHUD.dismiss()
                    if count > 0 {
                        self.books.removeAtIndex(indexPath.row)
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                }
            } catch let error {
                let alert = UIAlertController(
                    title: "Error",
                    message: "\(error)",
                    preferredStyle: .Alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    @IBAction func unwindToMasterView(segue: UIStoryboardSegue) {
        reloadData()
    }
    
    @IBAction func refresh(sender: AnyObject) {
        reloadData()
    }

    @IBAction func pull(sender: AnyObject) {
        SVProgressHUD.show()
        
        //Pull data from the backend to the sync datastore
        store.pull() { (books, error) -> Void in
            SVProgressHUD.dismiss()
            if let books = books {
                self.books = books
            }
            self.tableView.reloadData();
        }
    }
    
    @IBAction func push(sender: AnyObject) {
        SVProgressHUD.show()
        
        //Push all local changes to the backend
        store.push { (count, error) -> Void in
            SVProgressHUD.dismiss()
            self.reloadData()
        }
    }
    
    @IBAction func purge(sender: AnyObject) {
        SVProgressHUD.show()
        
        //Discard all local changes
        store.purge { (count, error) -> Void in
            SVProgressHUD.dismiss()
            self.reloadData()
        }
    }
    
    @IBAction func sync(sender: AnyObject) {
        SVProgressHUD.show()
        
        //Sync with the backend. 
        //This will push all local changes to the backend, then
        //pull changes from the backend to the app.
        store.sync() { (count, books, errors) -> Void in
            SVProgressHUD.dismiss()
            if let books = books {
                self.books = books
                self.tableView.reloadData();
            } else if let errors = errors, let error = errors.first {
                if let error = error as? Error {
                    switch error {
                    case .Unauthorized(let error, let description):
                        let alert = UIAlertController(title: error, message: description, preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (alertAction) in
                            alert.dismissViewControllerAnimated(true, completion: nil)
                        }))
                        self.presentViewController(alert, animated: true, completion: nil)
                    default:
                        self.presentError(error as NSError)
                    }
                } else {
                    self.presentError(error as NSError)
                }
            }
        }
    }
    
    func presentError(error: NSError) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (alertAction) in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        reloadData(searchText)
    }
    
}

