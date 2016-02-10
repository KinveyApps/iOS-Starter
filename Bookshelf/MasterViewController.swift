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

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var books = [Book]()
    var selectedBook: Book?
    
    lazy var store: DataStore<Book>! = {
        return DataStore<Book>.getInstance(.Sync)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewBook:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        reloadData()
    }
    
    func reloadData() {
        SVProgressHUD.show()
        store.find() { (books, error) -> Void in
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
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
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
            try! store.remove(book) { (count, error) -> Void in
            }
            
            books.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedBook = books[indexPath.row]
    }
    
    @IBAction func unwindToMasterView(segue: UIStoryboardSegue) {
        reloadData()
    }
    
    @IBAction func refresh(sender: AnyObject) {
        reloadData()
    }

    @IBAction func push(sender: AnyObject) {
        let store = DataStore<Book>.getInstance(.Sync)
        SVProgressHUD.show()
        try! store.push { (count, error) -> Void in
            SVProgressHUD.dismiss()
            self.reloadData()
        }
    }
    
    @IBAction func purge(sender: AnyObject) {
        let store = DataStore<Book>.getInstance(.Sync)
        SVProgressHUD.show()
        try! store.purge { (count, error) -> Void in
            SVProgressHUD.dismiss()
            self.reloadData()
        }
    }
    
    @IBAction func sync(sender: AnyObject) {
        let store = DataStore<Book>.getInstance(.Sync)
        SVProgressHUD.show()
        try! store.sync() { (count, books, error) -> Void in
            SVProgressHUD.dismiss()
            self.reloadData()
        }
    }
}

