//
//  MembersTableViewController.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/9/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import UIKit

class MembersTableViewController: UITableViewController {
    // MARK: - Variables
    var usersRef = Database.database().reference(withPath: "users");
    var emailsRef = Database.database().reference(withPath: "emails");
    var invitesRef = Database.database().reference(withPath: "invites");
    var listRef: DatabaseReference!
    
    var listID: String!
    var listOwnerName: String!
    
    var joinedUsers: [(id: String, name: String)] = [];
    var invitedUsers: [(id: String, name: String)] = [];
    
    // MARK: - IBActions
    @IBAction func addMember(_ sender: Any) {
        let alert = UIAlertController(title: "Add Member", message: "", preferredStyle: .alert);
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { _ in
            guard let textField = alert.textFields?.first,
                let email = textField.text else { return; }
            
            // Email validation
            if(email == Auth.auth().currentUser!.email!) {
                Utility.presentErrorAlert(message: "You cannot invite yourself.", from: self);
                return;
            }
            
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            self.emailsRef.observeSingleEvent(of: .value, with: { snapshot in
                let recipientEmailAsID = User.emailToID(email);
                if(snapshot.hasChild(recipientEmailAsID)) {
                    let snapshotValue = snapshot.value as! [String: String];

                    let recipientID = snapshotValue[recipientEmailAsID]!;
                    let senderID = Auth.auth().currentUser!.uid;
                    let invite = (listID: self.listID, senderID: senderID);
                    
                    // Add to INVITES
                    let inviteRef = self.invitesRef.childByAutoId();
                    let inviteID = inviteRef.key;
                    inviteRef.child("listID").setValue(invite.listID!);
                    inviteRef.child("senderID").setValue(invite.senderID);
                    
                    // Add invite to USERS inviteIDs
                    let recipientUserRef = self.usersRef.child(recipientID);
                    recipientUserRef.child("inviteIDs").child(inviteID).setValue(true);
                    
                    // Add recipient to LISTS invitedIDs
                    self.listRef.child("invitedIDs").child(recipientID).setValue(true);
                } else {
                    Utility.presentErrorAlert(message: "User with email \"\(email)\" does not exist.", from: self);
                }
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            });
        });
        saveAction.isEnabled = false;
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel);
        
        alert.addTextField { itemNameTextField in
            itemNameTextField.autocapitalizationType = .words;
            itemNameTextField.placeholder = "Recipient Email";
        }
        
        alert.setupTextFields();
        
        alert.addAction(cancelAction);
        alert.addAction(saveAction);
        
        present(alert, animated: true, completion: nil);
    }
    
    // MARK: - Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listRef = Database.database().reference(withPath: "lists").child(listID);
        
        // Get list ownerID
        listRef.observeSingleEvent(of: .value, with: { snapshot in
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            let snapshotValue = snapshot.value as! [String: Any];
            let ownerID = snapshotValue["ownerID"] as! String;
            
            // Get owner's name
            self.usersRef.child(ownerID).observeSingleEvent(of: .value, with: { snapshot in
                let snapshotValue = snapshot.value as! [String: Any];
                self.listOwnerName = snapshotValue["name"] as! String;
                
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            });
        });
        
        // Load joined users
        listRef.child("memberIDs").observe(.value, with: { snapshot in
            var loadingMembers = false;
            
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            self.joinedUsers.removeAll();
            
            for case let snapshot as DataSnapshot in snapshot.children {
                loadingMembers = true;
                
                let memberID = snapshot.key;
                self.usersRef.child(memberID).child("name").observeSingleEvent(of: .value, with: { snapshot in
                    let memberName = snapshot.value as! String;
                    self.joinedUsers.append((memberID, memberName));
                });
                
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            }
            
            if(!loadingMembers) {
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            }
        });
        
        // Load invited users
        listRef.child("invitedIDs").observe(.value, with: { snapshot in
            var loadingMembers = false;
            
            Utility.showActivityIndicator(in: self.navigationController!.view!);
            
            self.invitedUsers.removeAll();
            
            for case let snapshot as DataSnapshot in snapshot.children {
                loadingMembers = true;
                
                let invitedID = snapshot.key;
                self.usersRef.child(invitedID).child("name").observeSingleEvent(of: .value, with: { snapshot in
                    let invitedName = snapshot.value as! String;
                    self.joinedUsers.append((invitedID, invitedName));
                });
                
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            }
            
            if(!loadingMembers) {
                self.tableView.reloadData();
                Utility.hideActivityIndicator();
            }
        });
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return joinedUsers.count + invitedUsers.count + 1;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "membersCell")!;
        
        if(indexPath.row == 0) {
            cell.textLabel!.text = listOwnerName;
            cell.detailTextLabel!.text = "Owner";
        } else if(indexPath.row <= joinedUsers.count) {
            let index = indexPath.row-1; // Offset due to owner
        
            cell.textLabel!.text = joinedUsers[index].name;
            cell.detailTextLabel!.text = "Joined";
        } else {
            let index = indexPath.row-joinedUsers.count-1; // Offset due to owner+members
            
            cell.textLabel!.text = invitedUsers[index].name;
            cell.detailTextLabel!.text = "Invited";
        }

        return cell;
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        switch(editingStyle) {
        case .delete:
            break;
        default:
            break;
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0;
    }
}
