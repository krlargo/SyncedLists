//
//  ItemsTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/16/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseDatabase
import Foundation
import UIKit

class ItemsTableViewController: UITableViewController {

    // MARK: - Variables
    var listID: String!
    let itemsRef = Database.database().reference(withPath: "items");
    var items: [Item] = [];
    //var user: User!
    var user = User(name: "Kevin", email: "krlargo@ucdavis.edu");
    
    // MARK: - IBActions
    @IBAction func addItem(_ sender: Any) {
        let alert = UIAlertController(title: "Item", message: "Add Item", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ in
            
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return; }
            
            let item = Item(name: text, addedByUser: self.user.email);
            let itemRef = self.itemsRef.childByAutoId();
            itemRef.setValue(item.toAnyObject());
            
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

        var currentListItemsRef = itemsRef.child(listID);
        currentListItemsRef.observe(.value, with: { snapshot in
            var loadedItems: [Item] = [];
            
            for case let snapshot as DataSnapshot in snapshot.children {
                let item = Item(snapshot: snapshot);
                loadedItems.append(item);
            }
            
            self.items = loadedItems;
            
            defer {
                self.tableView.reloadData();
            }
        })
        
        /*itemsRef.observe(.value, with: { snapshot in
            var newItems: [Item] = [];

            for case let snapshot as DataSnapshot in snapshot.children {
                let item = Item(snapshot: snapshot);
                newItems.append(item);
            }
            
            self.items = newItems;
            defer { // Reload tableData when observe is completed
                self.tableView.reloadData();
            }
        })*/
    }

    // MARK: - TableView Delegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") as! ItemCell;
        let item = items[indexPath.row];
        
        cell.itemNameLabel.text = item.name;
        cell.addedByLabel.text = "Added: \(user.name)";
    
        //cell.completedByLabel.text = "\(item.isCompleted ? "Completed: \(item.completedBy)" : "")"
        cell.completedByLabel.text = ""; ///TEMP

        cell.accessoryType = (item.completedBy != nil ? .checkmark : .none);
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var item = items[indexPath.row];
        
        item.completedBy = (item.completedBy != nil ? user.name : nil);

        item.ref?.updateChildValues(["completedBy": item.completedBy]);
        
        tableView.reloadData();
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch(editingStyle) {
        case .delete:
            let item = items[indexPath.row];
            item.ref?.removeValue();
        default:
            return;
        }
    }
}

class ItemCell: UITableViewCell {
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var addedByLabel: UILabel!
    @IBOutlet weak var completedByLabel: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
}
