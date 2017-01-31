//
//  AuthorsTableViewController.swift
//  Bookshelf
//
//  Created by Victor Hugo on 2017-01-31.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import UIKit
import RealmSwift

class AuthorTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField!
    
    var authorChanged: ((Author?) -> Void)?
    var author: Author? {
        didSet {
            if let author = author,
                let firstName = author.firstName,
                !firstName.isEmpty,
                let lastName = author.lastName,
                !lastName.isEmpty
            {
                textField.text = "\(firstName) \(lastName)"
            } else {
                textField.text = ""
            }
            authorChanged?(author)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let author = author,
            let text = textField.text,
            !text.isEmpty,
            text.contains(" ")
        {
            var components = text.components(separatedBy: " ")
            author.firstName = components.first!
            components.removeFirst()
            author.lastName = components.joined(separator: " ")
        } else {
            author = nil
        }
        textField.resignFirstResponder()
        return false
    }
    
}

class AuthorsTableViewController: UITableViewController {
    
    var authors: [Author]!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return authors.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! AuthorTableViewCell
        
        let index = indexPath.row
        let author = authors[index]
        cell.author = author
        cell.authorChanged = { author in
            if author == nil {
                self.authors.remove(at: index)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
