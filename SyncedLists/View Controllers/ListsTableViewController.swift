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
    var currentUserRef: DatabaseReference!
    
    var lists: [List] = [];
    var user: User!
    
    // MARK: - IBActions
    @IBAction func logout(_ sender: Any) {}
    
    @IBAction func addList(_ sender: Any) {
        let alert = UIAlertController(title: "List", message: "Add List", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ in
            
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return; }
            
            // Add list to LISTS in database
            let list = List(name: text, owner: self.user.email);
            
            let newListRef = self.listsRef.childByAutoId();
            newListRef.setValue(list.toAnyObject());
            
            // Add list to USERS in database
            let currentUserListsRef = self.currentUserRef.child("listIDs");
            currentUserListsRef.child(newListRef.key).setValue(true);
            
            self.tableView.reloadData();
        });
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default);
        
        alert.setupTextFields();
        
        alert.addTextField();
        alert.addAction(saveAction);
        alert.addAction(cancelAction);
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Overridden Methods
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            guard let user = user else { return };
            self.user = User(authData: user);
        }
        print("viewWillAppear");
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        Auth.auth().removeStateDidChangeListener(handle!)
        print("viewWillDisappear");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = User(authData: Auth.auth().currentUser!);
        self.currentUserRef = usersRef.child(user.id); // Set reference
        
        // Set backButton
        let backButton = UIBarButtonItem();
        backButton.title = "Lists";
        navigationItem.backBarButtonItem = backButton;

        self.currentUserRef.child("listIDs").observe(.value, with: { snapshot in
            // Collect all the current user's list IDs
            self.lists.removeAll();
            for case let snap as DataSnapshot in snapshot.children {
                let listID = snap.key;
                let listRef = self.listsRef.child(listID);
                
                listRef.observeSingleEvent(of: .value, with: { listSnap in
                    let list = List(snapshot: listSnap, completionHandler: self.tableView.reloadData);
                    self.lists.append(list);
                    
                });
            }
        });
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
            let list = lists[indexPath.row];
            
            let userListRef = currentUserRef.child("listIDs").child(list.id!);
            userListRef.removeValue(); // Remove list from USERS
            list.ref?.removeValue(); // Remove list from LISTS
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
