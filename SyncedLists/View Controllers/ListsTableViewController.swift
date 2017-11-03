//
//  ListsTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/19/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import Foundation
import UIKit

class ListsTableViewController: UITableViewController {
    // MARK: - Variables
    let ref = Database.database().reference(withPath: "lists");
    var lists: [List] = [];
    //var user: User!
    var user = User(uid: "Kevin", email: "krlargo@ucdavis.edu");
    
    // MARK: - IBActions
    @IBAction func addList(_ sender: Any) {
        let alert = UIAlertController(title: "List", message: "Add List", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ in
            
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return; }
            
            let list = List(name: text, owner: self.user.email);
            //let listRef = self.ref.child(text.lowercased());
            let listRef = self.ref.childByAutoId();
            listRef.setValue(list.toAnyObject());
            
            self.tableView.reloadData();
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default);
        
        alert.addTextField();
        alert.addAction(saveAction);
        alert.addAction(cancelAction);
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref.observe(.value, with: { snapshot in
            var loadedLists: [List] = [];
            
            for case let snapshot as DataSnapshot in snapshot.children {
                let list = List(snapshot: snapshot, completionHandler: self.tableView.reloadData);
                loadedLists.append(list);
            }
            
            self.lists = loadedLists;
            self.tableView.reloadData();
        })
    }
    
    // MARK: - TableView Delegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell");
        let list = lists[indexPath.row];
        
        cell?.textLabel?.text? = list.name;
        cell?.detailTextLabel?.text? = "\(list.completedCount)/\(list.itemCount)";
        
        return cell!;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch(editingStyle) {
        case .delete:
            return; ///
        default:
            return;
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toItems") {
            if let indexPath = tableView.indexPathForSelectedRow {
                let itemsTVC = segue.destination as! ItemsTableViewController;
                itemsTVC.title = lists[indexPath.row].name;
                itemsTVC.itemsRef = lists[indexPath.row].ref?.child("items");
            }
        }
    }
}
