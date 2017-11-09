//
//  ItemsTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/16/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import Foundation
import UIKit

class ItemsTableViewController: UITableViewController {

    // MARK: - Variables
    var listID: String!
    var itemsRef = Database.database().reference(withPath: "items");
    
    var items: [Item] = [];
    var user: User!
    var handle: AuthStateDidChangeListenerHandle?

    // MARK: - IBActions
    @IBAction func addItem(_ sender: Any) {
        let alert = UIAlertController(title: "Add Item", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ in
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return; }
            
            let item = Item(name: text, addedBy: self.user);
            let itemRef = self.itemsRef.childByAutoId();
            itemRef.setValue(item.toAnyObject());
            
            self.tableView.reloadData();
        });
        saveAction.isEnabled = false;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel);
        
        alert.addTextField { itemNameTextField in
            itemNameTextField.autocapitalizationType = .words;
            itemNameTextField.placeholder = "List Name";
        }
        
        alert.setupTextFields();
        
        alert.addAction(cancelAction);
        alert.addAction(saveAction);
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = User(authData: Auth.auth().currentUser!);
        self.itemsRef = Database.database().reference(withPath: "items").child(listID);
        
        self.itemsRef.observe(.value, with: { snapshot in
            Utility.showActivityIndicator(in: self.navigationController?.view);

            var loadedItems: [Item] = [];
            
            for case let snapshot as DataSnapshot in snapshot.children {
                let item = Item(snapshot: snapshot, completionHandler: self.reloadData);
                loadedItems.append(item);
            }
            
            self.items = loadedItems;
            
            self.tableView.reloadData();
            Utility.hideActivityIndicator(); // In case there are no items;
        });
    }
    
    func reloadData() {
        self.tableView.reloadData();
        Utility.hideActivityIndicator();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            guard let user = user else { return };
            self.user = User(authData: user);
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    // MARK: - TableView Delegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (items.isEmpty) ? 1 : items.count;

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as! ItemCell;
        
        if(items.isEmpty) {
            tableView.allowsSelection = false;
            
            cell.textLabel!.text = "No Items";
            cell.textLabel!.textColor = UIColor.lightGray;
            
            cell.itemNameLabel.text = "";
            cell.addedByLabel.text = "";
            cell.completedByLabel.text = "";
            
            cell.accessoryType = .none;
            return cell;
        } else {
            tableView.allowsSelection = true;
            
            cell.textLabel!.text = "";
        }
        
        let item = items[indexPath.row];
        
        cell.itemNameLabel.text = item.name;
        cell.addedByLabel.text =
            (item.addedByUserName == nil) ?
            "" : "Added: \(item.addedByUserName!)";
        
        if(item.completedByUser == nil || item.completedByUserName == nil) {
            cell.completedByLabel.text = "";
            cell.accessoryType = .none;
        } else {
            cell.completedByLabel.text = "Completed: \(item.completedByUserName!)"
            cell.accessoryType = .checkmark;
        }
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row];
        
        if let completedByUser = item.completedByUser {
            item.completedByUser = nil;
            item.completedByUserName = nil;
        } else {
            item.completedByUser = user.id;
            item.completedByUserName = user.name;
        }
        
        item.ref?.updateChildValues(["completedByUser": item.completedByUser ?? NSNull()]);
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
