//
//  ListsTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 10/19/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import Foundation
import UIKit

class ListsTableViewController: UITableViewController {
    // MARK: - Variables
    let usersRef = Database.database().reference(withPath: "users");
    let listsRef = Database.database().reference(withPath: "lists");
    var userRef: DatabaseReference!
    
    var lists: [List] = [];
    var user: User!
    var handle: AuthStateDidChangeListenerHandle?

    // MARK: - IBActions
    @IBAction func addList(_ sender: Any) {
        let alert = UIAlertController(title: "Add List", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ in
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return; }
            
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            let list = List(name: text, ownerID: self.user.id);

            // Add to LISTS
            let listRef = self.listsRef.childByAutoId();
            listRef.setValue(list.toAnyObject());
            
            // Add to USERS
            let currentUserListsRef = self.userRef.child("listIDs");
            currentUserListsRef.child(listRef.key).setValue(true);
            
            self.reloadData();
        });
        saveAction.isEnabled = false;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel);
        
        alert.addTextField { listNameTextField in
            listNameTextField.autocapitalizationType = .words;
            listNameTextField.placeholder = "List Name";
        }
        
        alert.setupTextFields();
        
        alert.addAction(cancelAction);
        alert.addAction(saveAction);

        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = User(authData: Auth.auth().currentUser!);
        self.userRef = usersRef.child(user.id); // Set reference
        
        // Set backButton
        let backButton = UIBarButtonItem();
        backButton.title = "Lists";
        navigationItem.backBarButtonItem = backButton;

        self.userRef.child("listIDs").observe(.value, with: { snapshot in
            var loadingLists = false;
            Utility.showActivityIndicator(in: self.navigationController?.view);

            // Load user's lists
            self.lists.removeAll();
            for case let snapshot as DataSnapshot in snapshot.children {
                loadingLists = true;
                
                let listID = snapshot.key;
                let listRef = self.listsRef.child(listID);
                
                listRef.observeSingleEvent(of: .value, with: { snapshot in
                    let list = List(snapshot: snapshot, completionHandler: self.reloadData);
                    self.lists.append(list);
                });
            }
            
            if(!loadingLists) {
                self.reloadData();
            }
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
        return (lists.isEmpty) ? 1 : lists.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell");
        
        if(lists.isEmpty) {
            tableView.allowsSelection = false;
            
            cell!.textLabel!.text = "No SyncedLists";
            cell!.textLabel!.textColor = UIColor.lightGray;
            cell!.detailTextLabel?.text = "";
            cell!.accessoryType = .none;
        } else {
            tableView.allowsSelection = true;
            
            cell!.textLabel!.textColor = UIColor.darkText;
            cell!.accessoryType = .disclosureIndicator;
            
            let list = lists[indexPath.row];
            
            cell!.textLabel!.text! = list.name;
            cell!.detailTextLabel!.text! = "\(list.completedCount)/\(list.itemCount)";
        }
        
        return cell!;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch(editingStyle) {
        case .delete:
            let list = lists[indexPath.row];

            // Delete list from current user only
            let userListRef = userRef.child("listIDs").child(list.id!);
            userListRef.removeValue(); // Remove list from user in USER

            // If current user is list owner, then delete entire list
            if(list.ownerID == user.id) {
                list.delete();
            } else { // Otherwise, delete memberID from list's memberIDs
                let listRef = listsRef.child(list.id!);
                listRef.child("memberIDs").child(user.id).removeValue();
            }
        default:
            return;
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toItems") {
            if let indexPath = tableView.indexPathForSelectedRow {
                let itemsTVC = segue.destination as! ItemsTableViewController;
                itemsTVC.title = lists[indexPath.row].name;
                itemsTVC.listID = lists[indexPath.row].id;
            }
        }
    }
}
