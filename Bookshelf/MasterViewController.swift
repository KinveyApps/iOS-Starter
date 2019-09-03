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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MasterViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!

    var detailViewController: DetailViewController? = nil
    var books = AnyRandomAccessCollection<Book>([])
    var selectedBook: Book?
    
    lazy var store: DataStore<Book>! = {
        //Create a DataStore of type "Sync"
        return try! DataStore<Book>.collection(.sync)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MasterViewController.insertNewBook(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        reloadData()
    }
    
    func reloadData(_ searchText: String = "") {
        SVProgressHUD.show()
        var query: Query
        if (searchText != "") {
            query = Query(format: "title CONTAINS[c] %@", searchText)
        } else {
            query = Query()
        }
        store.find(query, options: nil) { (result: Result<AnyRandomAccessCollection<Book>, Swift.Error>) in
            SVProgressHUD.dismiss()
            switch result {
            case .success(let books):
                self.books = books
            case .failure(let error):
                self.books = AnyRandomAccessCollection<Book>([])
                let alert = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                self.present(alert, animated: true)
            }
            if self.refreshControl?.isRefreshing ?? false {
                self.refreshControl?.endRefreshing()
            }
            self.tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func insertNewBook(_ sender: AnyObject) {
        selectedBook = Book()
        performSegue(withIdentifier: "showDetail", sender: sender)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let index = self.tableView.indexPathForSelectedRow {
                selectedBook = books[(index as NSIndexPath).row];
            }
            let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            controller.store = self.store
            controller.book = selectedBook
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(books.count)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let book = books[(indexPath as NSIndexPath).row]
        cell.textLabel!.text = book.title
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let book = books[indexPath.row]
            do {
                SVProgressHUD.show()
                try store.remove(book, options: nil) {
                    SVProgressHUD.dismiss()
                    switch $0 {
                    case .success(let count):
                        if count > 0, let bookIdToBeRemoved = book.entityId {
                            self.books = AnyRandomAccessCollection(self.books.lazy.filter({ (book) -> Bool in
                                return book.entityId != bookIdToBeRemoved
                            }))
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    case .failure:
                        break
                    }
                }
            } catch let error {
                let alert = UIAlertController(
                    title: "Error",
                    message: "\(error)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    @IBAction func unwindToMasterView(_ segue: UIStoryboardSegue) {
        reloadData()
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        reloadData()
    }

    @IBAction func pull(_ sender: AnyObject) {
        SVProgressHUD.show()
        
        //Pull data from the backend to the sync datastore
        store.pull(options: nil) {
            SVProgressHUD.dismiss()
            switch $0 {
            case .success(let books):
                self.books = books
                self.tableView.reloadData()
            case .failure:
                break
            }
        }
    }
    
    @IBAction func push(_ sender: AnyObject) {
        SVProgressHUD.show()
        
        //Push all local changes to the backend
        store.push(options: nil) {
            SVProgressHUD.dismiss()
            switch $0 {
            case .success(let count):
                print("\(count) items pushed")
            case .failure(let errors):
                for error in errors {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                }
            }
            self.reloadData()
        }
    }
    
    @IBAction func purge(_ sender: AnyObject) {
        SVProgressHUD.show()
        
        //Discard all local changes
        store.purge { _ in
            SVProgressHUD.dismiss()
            self.reloadData()
        }
    }
    
    @IBAction func sync(_ sender: AnyObject) {
        SVProgressHUD.show()
        
        //Sync with the backend. 
        //This will push all local changes to the backend, then
        //pull changes from the backend to the app.
        store.sync(options: nil) {
            SVProgressHUD.dismiss()
            switch $0 {
            case .success(_, let books):
                self.books = books
                self.tableView.reloadData();
            case .failure(let errors):
                if let error = errors.first {
                    self.present(error: error)
                }
            }
        }
    }
    
    func present(error: Swift.Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alertAction) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        reloadData(searchText)
    }
    
}

